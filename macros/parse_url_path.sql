{% macro parse_url_path(url_column) %}
    {% if target.type == 'bigquery' %}
        net.path({{ url_column }})
    {% else %}
        parse_url({{ url_column }}):path::string
    {% endif %}
{% endmacro %}
