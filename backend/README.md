# Veritas Laravel REST API

Laravel 12 / PHP ^8.2 backend for the Flutter app in `../frontend`.
Local development uses SQLite. Clinic branch, report, and batch data is
persisted through Eloquent models and exposed as JSON under `/api/v1`.

## Run from the repository root

```powershell
.\scripts\artisan.cmd migrate
.\scripts\artisan.cmd db:seed --class=ClinicDemoSeeder
.\scripts\artisan.cmd serve --host=127.0.0.1 --port=8000
```

The seed is explicit and preserves existing edits when rerun. On another
machine use `php artisan` from this folder after fresh-clone setup in the
[root README](../README.md).

## Routes

| Method | Path |
|---|---|
| GET | /api/v1/branches |
| GET | /api/v1/reports |
| PUT | /api/v1/branches/{id}/reports/{YYYY-MM-DD} |
| GET | /api/v1/medicine-batches |
| POST | /api/v1/medicine-batches |
| PATCH | /api/v1/medicine-batches/{id} |

Use JSON with `Accept: application/json` and `Content-Type: application/json`.
See [ARCHITECTURE.md](../ARCHITECTURE.md) for bodies, status codes, limits,
and persistence behavior. The health endpoint is `/up`.

## Development boundary

`LocalClinicApi` permits the clinic routes only in local/testing environments.
Authentication, role/branch authorization, event/audit history, and approval
flows are not implemented. CORS permits localhost/127.0.0.1 browser origins
for local Flutter development.

A deployed API requires PHP hosting, HTTPS, authentication/policies, durable
database configuration, and reviewed origins. GitHub Pages cannot host PHP.
If configuring Apache, serve only this folder's `public` directory.

## Verification

From the repository root:

```powershell
.\scripts\artisan.cmd test
.\scripts\composer.cmd validate --strict
.\scripts\composer.cmd check-platform-reqs
```

Feature tests use an isolated in-memory SQLite database. Your local `.env`,
application key, SQLite file, and vendor dependencies remain ignored.

Framework reference: [Laravel 12 documentation](https://laravel.com/docs/12.x).
