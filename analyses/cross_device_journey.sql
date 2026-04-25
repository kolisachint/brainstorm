with party_journey as (
    select
        s.session_id,
        s.party_id,
        s.visitor_id,
        s.session_start_timestamp,
        s.landing_page,
        s.exit_page,
        s.session_revenue,
        s.device_sk,
        s.channel_sk,
        d.browser_name,
        d.operating_system,
        d.is_mobile,
        row_number() over (partition by s.party_id order by s.session_start_timestamp) as session_sequence,
        lag(s.session_start_timestamp) over (partition by s.party_id order by s.session_start_timestamp) as prev_session_ts,
        timestamp_diff(
            s.session_start_timestamp, 
            lag(s.session_start_timestamp) over (partition by s.party_id order by s.session_start_timestamp), 
            hour
        ) as hours_since_last_session
    from {{ ref('fct_sessions') }} s
    left join {{ ref('dim_devices') }} d on s.device_sk = d.device_sk
    where s.party_id = '{{ var("party_id", "") }}'
       or s.party_id in (select party_id from {{ ref('dim_party_profiles') }} where cross_device_visitors > 1 limit 10)
)

select
    party_id,
    session_sequence,
    session_id,
    visitor_id,
    session_start_timestamp,
    browser_name,
    operating_system,
    is_mobile,
    landing_page,
    exit_page,
    session_revenue,
    hours_since_last_session,
    case 
        when hours_since_last_session is null then 'first_session'
        when hours_since_last_session < 24 then 'same_day_return'
        when hours_since_last_session < 168 then 'week_return'
        else 'extended_return'
    end as return_pattern
from party_journey
order by party_id, session_sequence
