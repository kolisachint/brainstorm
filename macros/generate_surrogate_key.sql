{% macro generate_surrogate_key(fields) %}
    farm_fingerprint(concat(
        {% for field in fields %}
            coalesce(cast({{ field }} as string), '_dbt_null_')
            {% if not loop.last %}, '|', {% endif %}
        {% endfor %}
    ))
{% endmacro %}
