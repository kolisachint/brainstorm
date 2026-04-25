DECLARE visitor_id_to_delete STRING DEFAULT 'VISITOR_ID_TO_DELETE';

BEGIN TRANSACTION;

DELETE FROM `project.dataset.stg_adobe_events`
WHERE visitor_id = visitor_id_to_delete;

DELETE FROM `project.dataset.fct_events`
WHERE visitor_id = visitor_id_to_delete;

DELETE FROM `project.dataset.fct_sessions`
WHERE visitor_id = visitor_id_to_delete;

DELETE FROM `project.dataset.dim_visitor_profiles`
WHERE visitor_id = visitor_id_to_delete;

COMMIT;

SELECT 'Visitor ' || visitor_id_to_delete || ' deleted from all tables' as result;
