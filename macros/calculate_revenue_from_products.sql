{% macro calculate_revenue_from_products(product_column) %}
    {% if target.type == 'bigquery' %}
        (
            select sum(safe_cast(split(product, ';')[ordinal(4)] as float64))
            from unnest(split({{ product_column }}, ',')) as product
            where product is not null and product != ''
        )
    {% else %}
        0
    {% endif %}
{% endmacro %}
