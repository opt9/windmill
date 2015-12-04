# Windmill API

Windmill has a comprehensive API for two different purposes:
- osquery clients use API endpoints as a part of their enrollment and to get the osquery configuration.
- To automate configuration & system management.

## API Endpoints

> These are the general API endpoints meant for managing osquery configurations and osquery enrolled systems.

### Configurations

| HTTP Method | Path | Action | Notes |
| ----------- | ---- | ------ | ----- |
| POST | /api/configurations | Creates a new configuration. | Requires read/write token. |
| GET | /api/configurations | Returns all configurations. | |
| GET | /api/configurations/[Configuration ID] | Returns the information on a given configuration. | |
| DELETE | /api/configurations/[Configuration ID] | Deletes given configuration. | Requires read/write token. |
| PATCH | /api/configurations/[Configuration ID] | Edits given configuration. | Requires read/write token. |

### Configuration Groups

| HTTP Method | Path | Action | Notes |
| ----------- | ---- | ------ | ----- |
| POST | /api/configuration_groups | Creates a new Configuration Group. | Requires read/write token. |
| GET | /api/configuration_groups | Gets information on all configuration groups. | |
| GET | /api/configuration_groups/[Configuration Group ID] | Gets information on a given configuration group. | |
| DELETE | /api/configuration_groups/[Configuration Group ID] | Deletes given configuration group. | Requires read/write token. |

### Endpoints

| HTTP Method | Path | Action | Notes |
| ----------- | ---- | ------ | ----- |
| GET | /api/endpoints | Retrieves information on all enrolled endpoints. | |
| GET | /api/endpoints/[ENDPOINT ID] | Retrieves information for a given endpoint. | |
| DELETE | /api/endpoints/[ENDPOINT ID] | Deletes an enrolled endpoint. | Requires read/write token. |

## Enrollment & Admin Endpoints

> These are not meant for general development and support API calls the osquery agent will make.

| HTTP Method | Path | Action | Notes |
| ----------- | ---- | ------ | ----- |
| POST | /api/enroll | Enrolls a new osquery endpoint. | Handled by osquery itself. |
| POST | /api/config | Allows an osquery endpoint to get the current configuration. | Handled by osquery itself. |
| GET | /api/status | Returns server status & current server time. | Used for testing... and time management. |
