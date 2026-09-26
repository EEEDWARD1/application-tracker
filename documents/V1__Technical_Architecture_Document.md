# Technical Architecture Document - Job Application Tracker
>**Project:** Application Tracker,
**Owners:** Eduard (repo owner) & Adam,
**Last Updated:** 2026-09-25,
**Status:** Draft v0.1

# 1. Summary
|**Layer** | **Technology**|
|---|---|
| Frontend | `React` `TypeScript` `TailwindCSS` |
| API Service | `ASP.NET Core Web API` `EF Core` `NPgsql`
|Auth Sercice | Seperate Service tbd
|Database | `PostgreSQL 17`
|File Storage | `PostgreSQL Blob`
|Email | tbd |
|Runtime | Docker Compose on a Proxmox VM
|Edge | Cloudflare Tunnel |
|Observability | Serilog on every service |
|CI/CD| GitHub actions - GHCR Images - Playwright end-to-end tests - deploy on merge to `main`

# 2. `Auth` - Authentication Service
**Responsibilities:** registration, email verification, login, logout, password rest, refresh-token rotation, account deletion, and publishing signing keys.

|Endpoint|Purpose|
|---|---|
|`POST /auth/register`|Create a user and send a verification email|