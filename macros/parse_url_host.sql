{% macro parse_url_host(url_column) %}
    {% if target.type == 'bigquery' %}
        net.host({{ url_column }})
    {% else %}
        parse_url({{ url_column }}):host::string
    {% endif %}
{% endmacro %}
