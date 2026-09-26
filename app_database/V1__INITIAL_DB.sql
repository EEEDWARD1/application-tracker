-- AppTrack: initial schema for PostgreSQL 15+
-- Run in a new database. The application writes the first stage history row
-- in the same transaction that creates an application.

CREATE TABLE users (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id TEXT NOT NULL UNIQUE, -- JWT subject; credentials live in the auth service
    username     TEXT,
    time_zone    TEXT NOT NULL DEFAULT 'Europe/London',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE companies (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    website_url  TEXT,
    notes        TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (id, user_id)
);

CREATE UNIQUE INDEX companies_user_name_uq ON companies (user_id, lower(company_name));

CREATE TABLE roles (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title      TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (id, user_id)
);

CREATE UNIQUE INDEX roles_user_title_uq ON roles (user_id, lower(title));

CREATE TABLE application_statuses (
    code        TEXT PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    sort_order  INTEGER NOT NULL UNIQUE,
    is_terminal BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE job_applications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_id      UUID NOT NULL,
    role_id         UUID NOT NULL,
    job_url         TEXT,
    location        TEXT,
    salary_min      INTEGER CHECK (salary_min >= 0),
    salary_max      INTEGER CHECK (salary_max >= 0),
    salary_currency CHAR(3) NOT NULL DEFAULT 'GBP',
    source          TEXT CHECK (source IN (
                        'LinkedIn', 'Indeed', 'Company Website',
                        'Graduate Scheme Site', 'Recruiter', 'Referral',
                        'Job Board', 'Other')),
    date_applied    DATE,
    archived        BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (id, user_id),
    CHECK (salary_min IS NULL OR salary_max IS NULL OR salary_min <= salary_max),
    FOREIGN KEY (company_id, user_id) REFERENCES companies(id, user_id),
    FOREIGN KEY (role_id, user_id) REFERENCES roles(id, user_id)
);

-- The latest row is the current stage; there is no second status column to sync.
CREATE TABLE application_stage_history (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_application_id UUID NOT NULL REFERENCES job_applications(id) ON DELETE CASCADE,
    status_code        TEXT NOT NULL REFERENCES application_statuses(code),
    changed_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    note               TEXT
);

CREATE TABLE notes (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_application_id UUID NOT NULL REFERENCES job_applications(id) ON DELETE CASCADE,
    body               TEXT NOT NULL, -- Markdown
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Includes application deadlines; they are no longer repeated on applications.
CREATE TABLE important_dates (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_application_id UUID NOT NULL REFERENCES job_applications(id) ON DELETE CASCADE,
    title              TEXT NOT NULL,
    type               TEXT NOT NULL CHECK (type IN (
                           'Interview', 'Assessment', 'Deadline', 'Offer Expiry', 'Other')),
    starts_at          TIMESTAMPTZ NOT NULL,
    all_day            BOOLEAN NOT NULL DEFAULT false,
    location_or_link   TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE contacts (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_id   UUID,
    contact_name TEXT NOT NULL,
    job_title    TEXT,
    email        TEXT,
    phone_number TEXT,
    linkedin_url TEXT,
    notes        TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (id, user_id),
    FOREIGN KEY (company_id, user_id) REFERENCES companies(id, user_id)
        ON DELETE SET NULL (company_id)
);

CREATE TABLE application_contacts (
    user_id            UUID NOT NULL,
    job_application_id UUID NOT NULL,
    contact_id         UUID NOT NULL,
    role               TEXT NOT NULL CHECK (role IN (
                           'Recruiter', 'Hiring Manager', 'Interviewer', 'Referrer', 'Other')),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (job_application_id, contact_id),
    FOREIGN KEY (job_application_id, user_id) REFERENCES job_applications(id, user_id)
        ON DELETE CASCADE,
    FOREIGN KEY (contact_id, user_id) REFERENCES contacts(id, user_id)
        ON DELETE CASCADE
);

CREATE TABLE interactions (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_application_id UUID,
    contact_id         UUID,
    type               TEXT NOT NULL CHECK (type IN (
                           'Email', 'Call', 'LinkedIn', 'Meeting', 'Other')),
    direction          TEXT NOT NULL CHECK (direction IN ('Inbound', 'Outbound')),
    occurred_at        TIMESTAMPTZ NOT NULL,
    subject            TEXT,
    body               TEXT,
    source             TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'sync')),
    external_id        TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (job_application_id IS NOT NULL OR contact_id IS NOT NULL),
    FOREIGN KEY (job_application_id, user_id) REFERENCES job_applications(id, user_id)
        ON DELETE SET NULL (job_application_id),
    FOREIGN KEY (contact_id, user_id) REFERENCES contacts(id, user_id)
        ON DELETE SET NULL (contact_id)
);

CREATE TABLE documents (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name       TEXT NOT NULL,
    type       TEXT NOT NULL CHECK (type IN (
                   'CV', 'Cover Letter', 'Portfolio', 'Transcript', 'Other')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (id, user_id)
);

CREATE TABLE document_versions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL,
    document_id  UUID NOT NULL,
    version_no   INTEGER NOT NULL CHECK (version_no >= 1),
    storage_key  TEXT NOT NULL UNIQUE,
    file_name    TEXT NOT NULL,
    content_type TEXT NOT NULL CHECK (content_type IN (
                     'application/pdf',
                     'application/vnd.openxmlformats-officedocument.wordprocessingml.document')),
    size_bytes   BIGINT NOT NULL CHECK (size_bytes BETWEEN 1 AND 10485760),
    sha256       CHAR(64) NOT NULL,
    uploaded_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (id, user_id),
    UNIQUE (document_id, version_no),
    FOREIGN KEY (document_id, user_id) REFERENCES documents(id, user_id)
        ON DELETE CASCADE
);

CREATE TABLE application_documents (
    user_id             UUID NOT NULL,
    job_application_id  UUID NOT NULL,
    document_version_id UUID NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (job_application_id, document_version_id),
    FOREIGN KEY (job_application_id, user_id) REFERENCES job_applications(id, user_id)
        ON DELETE CASCADE,
    FOREIGN KEY (document_version_id, user_id) REFERENCES document_versions(id, user_id)
        ON DELETE CASCADE
);

CREATE TABLE reminders (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_application_id UUID,
    title              TEXT NOT NULL,
    due_at             TIMESTAMPTZ NOT NULL,
    kind               TEXT NOT NULL DEFAULT 'manual' CHECK (kind IN (
                           'manual', 'auto_date', 'auto_stale')),
    status             TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
                           'pending', 'done', 'dismissed')),
    snoozed_until      TIMESTAMPTZ,
    dedupe_key         TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    FOREIGN KEY (job_application_id, user_id) REFERENCES job_applications(id, user_id)
        ON DELETE CASCADE
);

-- When the only linked parent is deleted, remove the interaction first.
-- Interactions with both links keep the surviving link via SET NULL above.
CREATE FUNCTION delete_single_parent_interactions() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_TABLE_NAME = 'contacts' THEN
        DELETE FROM interactions
        WHERE contact_id = OLD.id AND job_application_id IS NULL;
    ELSE
        DELETE FROM interactions
        WHERE job_application_id = OLD.id AND contact_id IS NULL;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER contacts_delete_interactions
    BEFORE DELETE ON contacts FOR EACH ROW
    EXECUTE FUNCTION delete_single_parent_interactions();

CREATE TRIGGER applications_delete_interactions
    BEFORE DELETE ON job_applications FOR EACH ROW
    EXECUTE FUNCTION delete_single_parent_interactions();

-- Current stage, obtained from the single source of truth.
CREATE VIEW application_current_status AS
SELECT a.id AS job_application_id, s.status_code, s.changed_at
FROM job_applications AS a
LEFT JOIN LATERAL (
    SELECT h.status_code, h.changed_at
    FROM application_stage_history AS h
    WHERE h.job_application_id = a.id
    ORDER BY h.changed_at DESC, h.id DESC
    LIMIT 1
) AS s ON true;

-- Indexes for tenant queries, recent activity, and FK deletes.
CREATE INDEX job_applications_user_idx ON job_applications (user_id, created_at DESC);
CREATE INDEX job_applications_company_idx ON job_applications (company_id);
CREATE INDEX job_applications_role_idx ON job_applications (role_id);
CREATE INDEX stage_history_latest_idx
    ON application_stage_history (job_application_id, changed_at DESC, id DESC);
CREATE INDEX notes_application_idx ON notes (job_application_id);
CREATE INDEX important_dates_application_idx ON important_dates (job_application_id, starts_at);
CREATE INDEX contacts_company_idx ON contacts (company_id);
CREATE INDEX application_contacts_contact_idx ON application_contacts (contact_id);
CREATE INDEX interactions_user_idx ON interactions (user_id, occurred_at DESC);
CREATE INDEX interactions_application_idx ON interactions (job_application_id, occurred_at DESC);
CREATE INDEX interactions_contact_idx ON interactions (contact_id, occurred_at DESC);
CREATE UNIQUE INDEX interactions_external_uq ON interactions (user_id, external_id)
    WHERE external_id IS NOT NULL;
CREATE INDEX documents_user_idx ON documents (user_id);
CREATE INDEX document_versions_document_idx ON document_versions (document_id);
CREATE INDEX application_documents_version_idx ON application_documents (document_version_id);
CREATE INDEX reminders_user_due_idx ON reminders (user_id, status, due_at);
CREATE INDEX reminders_application_idx ON reminders (job_application_id);
CREATE UNIQUE INDEX reminders_dedupe_uq ON reminders (user_id, dedupe_key)
    WHERE dedupe_key IS NOT NULL;

INSERT INTO application_statuses (code, name, sort_order, is_terminal) VALUES
    ('wishlist',          'Wishlist',          1, false),
    ('applied',           'Applied',           2, false),
    ('pre_screening',     'Pre-Screening',     3, false),
    ('recruiter_call',    'Recruiter Call',    4, false),
    ('online_assessment', 'Online Assessment', 5, false),
    ('interviewing',      'Interviewing',      6, false),
    ('assessment_centre', 'Assessment Centre', 7, false),
    ('final_stage',       'Final Stage',       8, false),
    ('offer',             'Offer',             9, false),
    ('accepted',          'Accepted',         10, true),
    ('rejected',          'Rejected',         11, true),
    ('withdrawn',         'Withdrawn',        12, true),
    ('lapsed',            'Lapsed',           13, true);