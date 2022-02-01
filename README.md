# scenic_overlook
Review OHA Tableau Server Workbook Access and Usage

### Motivating questions

  - Can we identify under-utilized views or workbooks?
  - Who benefits from the workbook/view - SIEI, OHA, or missions?
  - Is access driven by email reminders (i.e. SIEI email about being updated)?
  - Are users viewing one or multiple tabs in a session?
  - How are users interacting with workbooks?
  - Do users spend a "significant" amount of time on a given view?
  
### Data Access

Starting at the end of January  2022, M/CIO has setup a monthly refresh of the Tableau Postgres DB to pull specified data fields. At this point, we only have data available for the prior 6 months. The SQLView is made available as a [data source on Tableau Server](https://tableau.usaid.gov/#/projects/218). In order to access the data, I have connected to the Tableau server data source from Tableau Desktop, exported the data as a csv, and then uploaded it to [Google Drive](https://drive.google.com/drive/folders/1cP4Gy2Ys3bIJoDknrlgDgEi6UQo9ogGs). You can access this via `Scripts/00_import.R`. 

### Codebook

| variable            | type    | description                                                                                                        | notes                                                                                                                |
|---------------------|---------|--------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| action_type         | string  | category of interaction event user took with Tableau Server - Access, Create, Delete, Publish, Send E-Mail, Update |                                                                                                                      |
| created_at          | date    | date and time event occured [M/D/Y H:M:S]                                                                          |                                                                                                                      |
| datasource_name     | string  | data source on Tableau Server interacted with                                                                      |                                                                                                                      |
| event_type_name     | string  | sub-category for action_type, providing more detail on the type of interaction (see Event Type table)              |                                                                                                                      |
| friendly_name       | string  | name of user (Last, First), some with Operating Unit information                                                   |                                                                                                                      |
| grant_allowed_by    | string  | source allowing user to have access to action_type - Allow by Group, Allow to User, Deny to User, NA               |                                                                                                                      |
| hist_event_id       | double  | unique indentifier for event                                                                                       |                                                                                                                      |
| is_failure          | logical | does the event fail?                                                                                               | all are false                                                                                                        |
| permissions_granted | string  | list of user's permissions                                                                                         |                                                                                                                      |
| project_name        | string  | workbook parent folder on Tableau Server                                                                           |                                                                                                                      |
| user_login_at       | date    | user session login [M/D/Y H:M:S]                                                                                   |                                                                                                                      |
| user_logout_at      | date    | user session logout [M/D/Y H:M:S]                                                                                  | very few data points                                                                                                 |
| user_name           | string  | user name (email)                                                                                                  |                                                                                                                      |
| user_or_group_name  | string  | group(s) associated with user_name for group access                                                                | when user has multiple groups they can appear on multiple rows (but will only have one created_at and hist_event_id) |
| view_name           | string  | Tableau workbook tab or view name                                                                                  |                                                                                                                      |
| workbook_name       | string  | Tableau workbook name                                                                                              |                                                                                                                      |
| worker              | string  | access point name                                                                                                  | value unclear                                                                                                        |
| datasource_id       | double  | unique identifier for datasource_name                                                                              |                                                                                                                      |
| duration_in_ms      | double  |                                                                                                                    | no values                                                                                                            |
| project_id          | double  | unique identifier for project_name                                                                                 |                                                                                                                      |
| type_id             | double  | unique identifier for project_name                                                                                 |                                                                                                                      |
| user_id             | double  | unique identifier for project_name                                                                                 |                                                                                                                      |
| view_id             | double  | unique identifier for project_name                                                                                 |                                                                                                                      |
| workbook_id         | double  | unique identifier for project_name                                                                                 |                                                                                                                      |

### Event Types

| action_type | event_type_name                       |
|-------------|---------------------------------------|
| Access      | Access Authoring View                 |
| Access      | Access Data Source                    |
| Access      | Access Metric                         |
| Access      | Access Summary ViewData               |
| Access      | Access Underlying ViewData            |
| Access      | Access View                           |
| Access      | Download Data Source                  |
| Access      | Download Flow                         |
| Access      | Download Workbook                     |
| Access      | Export Summary ViewData               |
| Access      | Export Underlying ViewData            |
| Create      | Create Metric                         |
| Create      | Create Project                        |
| Delete      | Delete Data Source                    |
| Delete      | Delete Flow                           |
| Delete      | Delete View                           |
| Delete      | Delete Workbook                       |
| Publish     | Publish Data Source                   |
| Publish     | Publish Flow                          |
| Publish     | Publish View                          |
| Publish     | Publish Workbook                      |
| Send E-Mail | Send Data Driven Alert (DDA) E-Mail   |
| Send E-Mail | Send Subscription E-Mail For View     |
| Send E-Mail | Send Subscription E-Mail For Workbook |
| Update      | Change Project Ownership From         |
| Update      | Change Project Ownership To           |
| Update      | Move Datasource From                  |
| Update      | Move Datasource To                    |
| Update      | Move Flow From                        |
| Update      | Move Flow To                          |
| Update      | Move Project From                     |
| Update      | Move Project To                       |
| Update      | Move Workbook From                    |
| Update      | Move Workbook To                      |
| Update      | Refresh Workbook Extract              |
| Update      | Run Flow                              |
| Update      | Update Data Source                    |
| Update      | Update Flow                           |
| Update      | Update Project                        |
| Update      | Update Workbook                       |

---

*Disclaimer: The findings, interpretation, and conclusions expressed herein are those of the authors and do not necessarily reflect the views of United States Agency for International Development. All errors remain our own.*
