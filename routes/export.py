import io
import openpyxl
from flask import Blueprint, send_file, current_app, jsonify
from routes.utils.decorators import require_superuser_or_admin
from sqlalchemy import text
from db import managed_connection
from extension import limiter
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

export_bp = Blueprint('export_bp', __name__)

@export_bp.route('/api/export', methods=['GET'])
@require_superuser_or_admin
@limiter.limit("2/minute")
def export_excel():
    """
    Export all products and their activities to an Excel file.

    Column order mirrors the website table exactly:
      Product Info → Routing Details (per activity) → BOM Details (per activity) → Product Totals
    """
    try:
        # ── Query ─────────────────────────────────────────────────────────────
        # Column order matches the UI left-to-right:
        #   1. Product metadata
        #   2. Per-activity: ROUTING DETAILS section columns
        #   3. Per-activity: ACUMATICA BOM section columns
        #   4. Product-level TOTALS (footer row equivalent)
        query = text("""
            SELECT
                -- ── Product Metadata ──────────────────────────────────────────
                p.inventory_id              AS "Inventory ID",
                p.revision_descr            AS "Revision Descr.",
                p.revision                  AS "Revision",
                p.quantity                  AS "Qty",
                p.product_type              AS "Product Type",
                p.fg_production_line        AS "FG Production Line",
                p.fg_production_line_code   AS "FG Production Line Code",
                p.bm_production_line        AS "BM Production Line",
                p.bm_production_line_code   AS "BM Production Line Code",
                p.notes                     AS "Notes",

                -- ── ROUTING DETAILS (per activity, matches UI columns) ────────
                a.activity_name             AS "Activities",
                a.pax                       AS "Pax",
                a.machine                   AS "Machine",
                a.time_min                  AS "Time (min)",
                a.run_time                  AS "Run Time",
                a.labor_min                 AS "Total Labor (min)",
                a.mc_min                    AS "Total MC (min)",

                -- ── ACUMATICA BOM (per activity, matches UI columns) ──────────
                a.dl_units                  AS "DL (UNITS/1 MIN)",
                a.dl                        AS "DL",
                a.voh                       AS "VOH",
                a.foh                       AS "FOH",

                -- ── Extra activity metadata ────────────────────────────────────
                a.type                      AS "Type",
                a."class"                   AS "CLASS",
                a.class_1                   AS "CLASS.1",
                a.item_id                   AS "Item ID",

                -- ── Product-level TOTALS (equivalent to the footer row) ────────
                p.total_run_time            AS "Total Run Time",
                p.total_labor_min           AS "Total Labor (min) [Sum]",
                p.total_mc_min              AS "Total MC (min) [Sum]",
                p.total_dl                  AS "Total DL [Sum]",
                p.total_voh                 AS "Total VOH [Sum]",
                p.total_foh                 AS "Total FOH [Sum]"

            FROM products p
            LEFT JOIN activities a ON p.inventory_id = a.inventory_id
            ORDER BY p.inventory_id, a.sort_order
            LIMIT 50000;
        """)

        with managed_connection() as conn:
            result = conn.execute(query)
            colnames = list(result.keys())
            rows = [tuple(row) for row in result.all()]

        # ── Build Workbook ─────────────────────────────────────────────────────
        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = "ACU Routing"

        # ── Colour palette (mirrors the website) ──────────────────────────────
        TEAL_FILL   = PatternFill("solid", fgColor="006666")   # section header teal
        YELLOW_FILL = PatternFill("solid", fgColor="FFFF99")   # routing input yellow
        BOM_FILL    = PatternFill("solid", fgColor="CCE5FF")   # bom blue
        TOTAL_FILL  = PatternFill("solid", fgColor="E2EFDA")   # totals green
        WHITE_FONT  = Font(bold=True, color="FFFFFF")
        BOLD_FONT   = Font(bold=True)

        # Section boundaries (1-indexed column numbers in the sheet)
        # Product metadata: cols 1-10
        # Routing Details:  cols 11-17
        # BOM Details:      cols 18-21
        # Extra metadata:   cols 22-25
        # Totals:           cols 26-31

        SECTION_RANGES = {
            "Product Info":      (1,  10, TEAL_FILL),
            "Routing Details":   (11, 17, YELLOW_FILL),
            "Acumatica BOM":     (18, 21, BOM_FILL),
            "Extra Info":        (22, 25, TEAL_FILL),
            "Product Totals":    (26, 31, TOTAL_FILL),
        }

        # Row 1: Section header row
        ws.append([None] * len(colnames))
        header_row = ws[1]
        for section_name, (start, end, fill) in SECTION_RANGES.items():
            ws.merge_cells(
                start_row=1, start_column=start,
                end_row=1,   end_column=end
            )
            cell = ws.cell(row=1, column=start)
            cell.value     = section_name
            cell.fill      = fill
            cell.font      = WHITE_FONT if fill in (TEAL_FILL,) else BOLD_FONT
            cell.alignment = Alignment(horizontal="center", vertical="center")

        # Row 2: Column name headers
        ws.append(colnames)
        for col_idx, col_name in enumerate(colnames, start=1):
            cell = ws.cell(row=2, column=col_idx)
            cell.font      = BOLD_FONT
            cell.alignment = Alignment(horizontal="center", wrap_text=True)
            # Colour the header cell to match its section
            for _, (start, end, fill) in SECTION_RANGES.items():
                if start <= col_idx <= end:
                    cell.fill = fill
                    break

        # Row 3+: Data rows
        for row in rows:
            ws.append(list(row))

        # ── Auto-fit column widths ─────────────────────────────────────────────
        for col in ws.iter_cols(min_row=2, max_row=ws.max_row):
            max_length = 0
            col_letter = get_column_letter(col[0].column)
            for cell in col:
                cell.alignment = Alignment(wrap_text=True)
                if cell.value is not None:
                    cell_length = len(str(cell.value))
                    if cell_length > max_length:
                        max_length = cell_length
            ws.column_dimensions[col_letter].width = min(max_length + 2, 40)

        # Freeze the first two rows (section headers + column names)
        ws.freeze_panes = "A3"

        # ── Output ────────────────────────────────────────────────────────────
        out = io.BytesIO()
        wb.save(out)
        out.seek(0)

        return send_file(
            out,
            mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            as_attachment=True,
            download_name='acu_routing_export.xlsx'
        )

    except Exception as e:
        current_app.logger.error(f"Error exporting Excel: {e}")
        return jsonify({"error": str(e)}), 500
