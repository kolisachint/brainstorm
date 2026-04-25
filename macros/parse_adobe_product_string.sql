{% macro parse_adobe_product_string(product_column) %}
    {% if target.type == 'bigquery' %}
        array(
            select as struct
                split(product, ';')[ordinal(1)] as category,
                split(product, ';')[ordinal(2)] as product_name,
                safe_cast(split(product, ';')[ordinal(3)] as int64) as quantity,
                safe_cast(split(product, ';')[ordinal(4)] as float64) as price
            from unnest(split({{ product_column }}, ',')) as product
            where product is not null and product != ''
        )
    {% else %}
        null
    {% endif %}
{% endmacro %}
