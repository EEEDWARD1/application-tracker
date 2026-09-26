/* V1__INITIAL_DB.sql
   Defines the initial database schema for the application tracker.
*/

/* Users Stored user information; auth itself lives in the auth microservice */
CREATE TABLE users (
    id           UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    auth_user_id TEXT NOT NULL UNIQUE,
    username     TEXT,
    email        TEXT NOT NULL UNIQUE,
    created_at   TIMESTAMPTZ DEFAULT now(),
    updated_at   TIMESTAMPTZ DEFAULT now()
);

/* Companies
---------------------------------------------------------------------------
   - Owned by a single user
   - Names are unique per user, not globally
   - UNIQUE (id, user_id) is the target of the composite FK from
     job_applications, so an application can only use its owner's companies
*/
CREATE TABLE companies (
    id           UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    user_id      UUID NOT NULL,
    company_name TEXT NOT NULL,
    website_url  TEXT NOT NULL,
    CONSTRAINT uq_companies_user_name UNIQUE (user_id, company_name),
    CONSTRAINT uq_companies_id_user   UNIQUE (id, user_id)
);

/* Roles (job titles)
---------------------------------------------------------------------------
   - Owned by a single user
   - titles are unique per user, not globally
*/
CREATE TABLE roles (
    id      UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    user_id UUID NOT NULL,
    role    TEXT NOT NULL,
    CONSTRAINT uq_roles_user_role UNIQUE (user_id, role),
    CONSTRAINT uq_roles_id_user   UNIQUE (id, user_id)
);

/* Application statuses
   - Fixed pipeline stages
   - is_terminal marks exit points (Rejected / Withdrawn / Lapsed)
     that can occur from any stage
*/
CREATE TABLE application_statuses (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    name        TEXT NOT NULL UNIQUE,
    sort_order  INT NOT NULL UNIQUE,
    is_terminal BOOLEAN NOT NULL DEFAULT false
);

/* !!!!!!!!!! Core tables !!!!!!!!*/

/* Job applications
---------------------------------------------------------------------------
   - status_id is the CURRENT stage (fast filtering for list/board views)
   - full stage history lives in application_stage_history
   - applied_at is nullable: Wishlist items haven't been applied to yet
*/
CREATE TABLE job_applications (
    id         UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    user_id    UUID NOT NULL,
    company_id UUID NOT NULL,
    role_id    UUID NOT NULL,
    status_id  UUID NOT NULL,
    applied_at TIMESTAMPTZ,
    archived   BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

/* Application stage history
---------------------------------------------------------------------------
   - Append-only log of every stage an application enters,
     including the initial stage on creation
*/
CREATE TABLE application_stage_history (
    id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    job_application_id UUID NOT NULL,
    status_id          UUID NOT NULL,
    entered_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    note               TEXT
);

/* !!!!!!!!!!!!!!!!!!  Application child tables !!!!!!!!!!!!!!!!!!!!!!!!!!! */

CREATE TABLE contacts (
    id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    job_application_id UUID NOT NULL,
    contact_name       TEXT NOT NULL,
    phone_number       TEXT,
    email              TEXT,
    created_at         TIMESTAMPTZ DEFAULT now(),
    updated_at         TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE emails (
    id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    job_application_id UUID NOT NULL,
    subject            TEXT,
    body               TEXT,
    received_at        TIMESTAMPTZ,
    created_at         TIMESTAMPTZ DEFAULT now(),
    updated_at         TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE notes (
    id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    job_application_id UUID NOT NULL,
    body               TEXT NOT NULL,
    created_at         TIMESTAMPTZ DEFAULT now(),
    updated_at         TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE documents (
    id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    job_application_id UUID NOT NULL,
    file_name          TEXT NOT NULL,
    file_url           TEXT NOT NULL,
    created_at         TIMESTAMPTZ DEFAULT now(),
    updated_at         TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE important_dates (
    id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    job_application_id UUID NOT NULL,
    label              TEXT NOT NULL, -- e.g. 'Interview', 'Deadline'
    date_at            TIMESTAMPTZ NOT NULL,
    created_at         TIMESTAMPTZ DEFAULT now(),
    updated_at         TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE reminders (
    id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
    job_application_id UUID NOT NULL,
    message            TEXT NOT NULL,
    remind_at          TIMESTAMPTZ NOT NULL,
    completed          BOOLEAN NOT NULL DEFAULT false,
    created_at         TIMESTAMPTZ DEFAULT now(),
    updated_at         TIMESTAMPTZ DEFAULT now()
);

/* Table relationships
---------------------------------------------------------------------------
GDPR erasure: deleting a row from users cascades to
companies, roles and job_applications, and from
job_applications to every child table, so all of a user's
data is removed in one DELETE.

job_applications -> companies / roles use composite FKs on
(id, user_id), so an application can only reference companies
and roles owned by the same user. They are NO ACTION rather
than RESTRICT: NO ACTION is checked at the end of the
statement, so a user delete can cascade through both paths
without tripping over ordering, while deleting a company or
role that is still in use on its own is still blocked.

application_statuses is a shared lookup with no personal data, so its FKs are RESTRICT.*/

ALTER TABLE companies
    ADD CONSTRAINT fk_companies_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE;

ALTER TABLE roles
    ADD CONSTRAINT fk_roles_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE;

ALTER TABLE job_applications
    ADD CONSTRAINT fk_job_applications_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE;

ALTER TABLE job_applications
    ADD CONSTRAINT fk_job_applications_company
    FOREIGN KEY (company_id, user_id) REFERENCES companies(id, user_id)
    ON DELETE NO ACTION;

ALTER TABLE job_applications
    ADD CONSTRAINT fk_job_applications_role
    FOREIGN KEY (role_id, user_id) REFERENCES roles(id, user_id)
    ON DELETE NO ACTION;

ALTER TABLE job_applications
    ADD CONSTRAINT fk_job_applications_status
    FOREIGN KEY (status_id) REFERENCES application_statuses(id)
    ON DELETE RESTRICT;

ALTER TABLE application_stage_history
    ADD CONSTRAINT fk_stage_history_job_application
    FOREIGN KEY (job_application_id) REFERENCES job_applications(id)
    ON DELETE CASCADE;

ALTER TABLE application_stage_history
    ADD CONSTRAINT fk_stage_history_status
    FOREIGN KEY (status_id) REFERENCES application_statuses(id)
    ON DELETE RESTRICT;

ALTER TABLE contacts
    ADD CONSTRAINT fk_contacts_job_application
    FOREIGN KEY (job_application_id) REFERENCES job_applications(id)
    ON DELETE CASCADE;

ALTER TABLE emails
    ADD CONSTRAINT fk_emails_job_application
    FOREIGN KEY (job_application_id) REFERENCES job_applications(id)
    ON DELETE CASCADE;

ALTER TABLE notes
    ADD CONSTRAINT fk_notes_job_application
    FOREIGN KEY (job_application_id) REFERENCES job_applications(id)
    ON DELETE CASCADE;

ALTER TABLE documents
    ADD CONSTRAINT fk_documents_job_application
    FOREIGN KEY (job_application_id) REFERENCES job_applications(id)
    ON DELETE CASCADE;

ALTER TABLE important_dates
    ADD CONSTRAINT fk_important_dates_job_application
    FOREIGN KEY (job_application_id) REFERENCES job_applications(id)
    ON DELETE CASCADE;

ALTER TABLE reminders
    ADD CONSTRAINT fk_reminders_job_application
    FOREIGN KEY (job_application_id) REFERENCES job_applications(id)
    ON DELETE CASCADE;

/*Indexes*/

CREATE INDEX idx_job_applications_user_id    ON job_applications (user_id);
CREATE INDEX idx_job_applications_company_id ON job_applications (company_id);
CREATE INDEX idx_job_applications_role_id    ON job_applications (role_id);
CREATE INDEX idx_job_applications_status_id  ON job_applications (status_id);

CREATE INDEX idx_stage_history_application_entered
    ON application_stage_history (job_application_id, entered_at);

CREATE INDEX idx_contacts_job_application_id        ON contacts (job_application_id);
CREATE INDEX idx_emails_job_application_id          ON emails (job_application_id);
CREATE INDEX idx_notes_job_application_id           ON notes (job_application_id);
CREATE INDEX idx_documents_job_application_id       ON documents (job_application_id);
CREATE INDEX idx_important_dates_job_application_id ON important_dates (job_application_id);
CREATE INDEX idx_reminders_job_application_id       ON reminders (job_application_id);

/* Seed data: fixed pipeline stages */

INSERT INTO application_statuses (name, sort_order, is_terminal) VALUES
    ('Wishlist',          1,  false),
    ('Applied',           2,  false),
    ('Pre-Screening',     3,  false),
    ('Recruiter Call',    4,  false),
    ('Online Assessment', 5,  false),
    ('Interviewing',      6,  false),
    ('Assessment Centre', 7,  false),
    ('Final Stage',       8,  false),
    ('Offer',             9,  false),
    ('Accepted',          10, true),
    ('Rejected',          11, true),
    ('Withdrawn',         12, true),
    ('Lapsed',            13, true);