DECLARE @hourspan INT = ?;
DECLARE @projectNamePattern NVARCHAR(100) = ?;
DECLARE @executionId BIGINT = ?;

WITH cteEID as
(
	SELECT execution_id FROM [catalog].executions e WHERE 
	e.project_name LIKE @projectNamePattern AND
	(@executionId = -1 AND e.start_time >= DATEADD(HOUR, -@hourspan, SYSDATETIME())) OR (e.execution_id = @executionId)
),
cteE AS
(
	SELECT errors = COUNT(*) FROM [catalog].event_messages em WHERE em.operation_id IN (SELECT c.execution_id FROM cteEID c)  AND em.event_name = 'OnError'
),
cteDW AS
(
	SELECT duplicate_warnings = COUNT(*) FROM [catalog].event_messages em WHERE em.operation_id IN (SELECT c.execution_id FROM cteEID c) AND em.event_name = 'OnWarning' AND [message] LIKE '%duplicate%' 
),
cteMW AS
(
	SELECT memory_warnings = COUNT(*) FROM [catalog].event_messages em WHERE em.operation_id IN (SELECT c.execution_id FROM cteEID c) AND em.event_name = 'OnInformation' AND [message] LIKE '%memory allocation%' 
)
SELECT
	*
FROM
	cteE, cteDW, cteMW
OPTION
	(RECOMPILE)