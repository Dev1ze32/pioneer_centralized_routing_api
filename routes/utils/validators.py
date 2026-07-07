from sqlalchemy import text

def validate_product_payload(body, conn):
    """
    Validates a product payload (for ADD operations).
    Returns (cleaned_body, error_message, status_code).
    If valid, error_message is None.
    """
    inventory_id = (body.get("inventory_id") or "").strip().upper()
    if not inventory_id:
        return None, "inventory_id is required", 400

    quantity = body.get("quantity")
    if quantity in (None, ""):
        quantity = 0.0
    else:
        try:
            quantity = float(quantity)
        except (TypeError, ValueError):
            return None, "quantity must be a number", 400

    if quantity != int(quantity):
        return None, "quantity must be a whole number", 400
        
    # Update body with cleaned values
    body["inventory_id"] = inventory_id
    body["quantity"] = quantity
    
    raw_activities = body.get("activities", [])
    for idx, act in enumerate(raw_activities):
        if not (act.get("activity_name") or "").strip():
            return None, f"Activity at index {idx} is missing a non-empty activity_name", 400
            
    # Validate production line codes against the production_lines table
    for code_field in ("fg_production_line_code", "bm_production_line_code"):
        code = body.get(code_field)
        if code:
            row = conn.execute(
                text("SELECT 1 FROM production_lines WHERE production_line_code = :c"),
                {"c": code},
            ).first()
            if not row:
                return None, f"{code_field} '{code}' does not exist", 400
                
    return body, None, 200