select
    identity_confidence_level,
    count(distinct party_sk) as party_count,
    count(distinct visitor_sk) as visitor_count,
    avg(total_visitors_for_party) as avg_devices_per_party,
    sum(session_count) as total_sessions,
    sum(event_count) as total_events
from {{ ref('party_visitor_mapping') }}
group by identity_confidence_level
order by 
    case identity_confidence_level
        when 'crm_enriched' then 1
        when 'loyalty_enriched' then 2
        when 'login_enriched' then 3
        else 4
    end
