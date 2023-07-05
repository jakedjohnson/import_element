# ImportElement

A service for bulk uploading spreadsheet data to the Method API. The frontend dashboard can be used in used in an `iframe`, offering the seamless element experience Method users are accustomed to.

# Technical Details

ImportElement is a web application powered by Phoenix. When TaxJar needed to scale their spreadsheet importer, they chose Elixir. A service built with Elixir gaurantees solid performance and painless scaling as import volume grows; it's a great choice whenever a feature (such as parsing and processing large sets of XML data in memory) requires speedy and reliable concurrency.

## Getting ImportElement running on a new machine

First install Erlang and Elixir.

If you use [asdf](https://asdf-vm.com/) for version management, then `.tool-versions` file contains the Elixir and Erlang versions required. You should only have to clone and open this repo and then run:

```
asdf install
```

Otherwise, here's where to download each:

- [Erlang](https://www.erlang.org/patches/otp-25.3.2.3)
- [Elixir](https://elixir-lang.org/install.html)

Erlang takes a while to do its thing. Once they are operational, start the Phoenix server in the repo's root directory:

- Run `mix setup` to install and setup the app's dependencies
- Start the application with `mix phx.server`, or with IEx (Interactive Elixir shell) using `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser to begin the import process.

# Implementation Details

The ImportElement is intended for authenticated users to bulk upload spreadsheets (XML) containing payment information between source (ACH?) accounts and destination (liability?) accounts.

There are two distinct layers to the backend logic:

- The core ImportElement application handles any processes pertaining to importing and exporting spreadsheet data. The `import_request` table stores and tracks everything related to the user's experience while using the element.
- The MethodEx dependency contains all knowledge of the Method API. It can validate a user's submitted data for API ingestible parameters, gives Elixir some structure for API-related objects, and handles all request and response logic.

## Feature #1 - Importing Payments

When a user uploads an XML of unique payments, ImportElement performs the following procedure:

1. A remote and local copy of the file are stored
2. An `import_request` gets created. This is the main object of the Import Element - each file uploaded equals a new `import_request`.

- `import_request.api_user_id` is the Method API user performing the spreadsheet upload (in this case, Dunkies). It should be associated to the API key used and/or `element_token` provided
- `import_request.status` - progress tracking
- `import_request.remote_store` - the storage location of the uploaded spreadsheet
- `import_request.local_store` - the locally stored spreadsheet for parsing

3. parses the XML data using the SweetXML Elixir Dependency
4. temporarily persists all entities, accounts, and payments in local application database

- separate `entity_details`, `account_details`, and `payment_details` tables
- all individual records must contain the `import_request_id`
- ? these locally stored details are only lighted validated prior to upsert (raw-er data is preferred for inevitable debugging purposes)
- the idea is to only query these temporary records for reasons pertaining to idempotency of API calls, so giving them all a `api_object_uuid` or `api_call_uuid`

5. validates the spreadsheet data contains acceptable API parameters

- Any invalidomits

6. upserts all records via the Method API

- `entity_details`, `account_details`, and `payment_details` are all structs mirroring the Method API
- `payment_details` are created/initialized for review, but not yet finalized
- ideally records persisted on Method's end would be given some `import_request_id` metadata/reference for easier querying from the element

7. the user confirms the payments displayed are accurate, or rejects the bunch

- if accepted, all payments are finalized

8. once all records are successfully uploaded via the API, the `import_request.status` is "completed" and the user should see all entities, accounts, and payments on their Method dashboard.

## Feature #2 - Exporting Reports

- 1. when an `import_request` is "completed", the user operating the import element can click to see more information about the import
- 2. the page showing information about the `import_request` allows for downloading 3 different report CSVs generated from the original XML data provided.
  - i) outgoing payment totals for each unique source account (5 different corporate checking accounts owned by Dunkin)
  - ii) outgoing payment totals per unique corporate entity (30 unique dunkin branches)
  - iii) the status of every payment and its relevant metadata
- 3. reports can be downloaded

# Some Reminders

- calls should be batched for reduced API traffic
- 10,000 unique individual entities (employees), belonging to 30 company entities (branches)
- sources should be 5 Dunkin owned checking accounts

# Future Considerations

- [ ] Authenticate logged in user via `api_key` or `element_token` request parameter?
- [ ] Better error handling on XML upload (bad param value formatting, XML syntax errors, etc)
- [ ] CSV upload ability (smaller files allow for more volume)
- [ ] Immediately send the XML file to remote storage on the client side
  - https://hexdocs.pm/phoenix_live_view/uploads-external.html
  - pros:
    - a carbon copy will help with debugging/testing in the future
  - cons:
    - XML is larger storage space
  - compliance considerations:
    - short and long term storage need to meet security standards
    - is there a documented data retention policy in place?
    - determine in advance what data we scrub & retain for business vs hard delete when users request
- [ ] move some work to async jobs or a messaging brokering system if errors increase, users experience timeouts, etc.
- [ ] Retries for failed API calls to the Method API
- [ ] Make the dashboard's endpoints part of Method's public API? (headless option for bulk upload)
