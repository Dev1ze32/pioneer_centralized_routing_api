import io
import openpyxl
from flask import Blueprint, send_file, current_app, jsonify
from routes.utils.decorators import require_superuser_or_admin
from sqlalchemy import text
from db import managed_connection

export_bp = Blueprint('export_bp', __name__)

@export_bp.route('/api/export', methods=['GET'])
@require_superuser_or_admin
def export_excel():
    """
    Export all products and their activities to an Excel file.
    The format repeats product information for each activity.
    """
    try:
        # Execute query joining products and activities.
        query = text("""
            SELECT 
                p.inventory_id AS "Inventory ID",
                p.revision_descr AS "Revision Descr.",
                p.revision AS "Revision",
                p.notes AS "Notes",
                p.product_type AS "Product Type",
                p.bm_production_line AS "BM Production Line",
                p.bm_production_line_code AS "BM Production Line Code",
                p.fg_production_line AS "FG Production Line",
                p.fg_production_line_code AS "FG Production Line Code",
                a.type AS "Type",
                a.item_id AS "Item ID",
                a.activity_name AS "ACTIVITIES",
                a.class AS "CLASS",
                a.class_1 AS "CLASS.1",
                a.pax AS "Pax",
                a.machine AS "Machine",
                a.time_min AS "Time (min)"
            FROM products p
            LEFT JOIN activities a ON p.inventory_id = a.inventory_id
            ORDER BY p.inventory_id, a.sort_order;
        """)
        
        with managed_connection() as conn:
            result = conn.execute(query)
            # Get column names
            colnames = list(result.keys())
            # Fetch all rows as list of tuples
            rows = [tuple(row) for row in result.all()]

        # Generate the Excel file
        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = "ACU Routing"

        # Write header
        ws.append(colnames)

        # Write data rows
        for row in rows:
            ws.append(row)

        from openpyxl.styles import Alignment

        # Auto-adjust column widths with a maximum cap and text wrapping
        for col in ws.columns:
            max_length = 0
            column_letter = col[0].column_letter # Get the column name
            for cell in col:
                # Enable text wrapping for all cells (especially useful for Notes)
                cell.alignment = Alignment(wrap_text=True)
                
                try:
                    # Calculate max width of the content
                    if cell.value:
                        cell_length = len(str(cell.value))
                        if cell_length > max_length:
                            max_length = cell_length
                except:
                    pass
            
            # Set the width: Add a little padding, but cap it at a maximum of 40 characters
            # so long columns like "Notes" don't take up the entire screen.
            adjusted_width = min((max_length + 2), 40)
            ws.column_dimensions[column_letter].width = adjusted_width

        # Save to memory buffer
        out = io.BytesIO()
        wb.save(out)
        out.seek(0)

        # Return file as download
        return send_file(
            out,
            mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            as_attachment=True,
            download_name='acu_routing_export.xlsx'
        )

    except Exception as e:
        current_app.logger.error(f"Error exporting Excel: {e}")
        return jsonify({"error": str(e)}), 500
