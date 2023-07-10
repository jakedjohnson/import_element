# ImportElement

A service for bulk uploading payment data to the Method API.

The ImportElement is intended for authenticated users to bulk upload spreadsheets (XML) containing payment information between source (ACH) accounts and destination (liability) accounts. Once the XML file is imported, the user should be able to download a CSV report of the associated payments created and fetched via the Method API.

# Technical Details

ImportElement is powered by Phoenix and LiveView. First and foremost, I wanted to work in the language I am most comfortable in. I also wanted to see if I could use LiveView to create a sort of single page, standalone application that could be deployed similar to current Method elements.

When TaxJar needed to scale their spreadsheet importer, they chose Elixir. A service built with Elixir gaurantees solid performance and painless scaling as import volume grows; it's a great choice whenever a feature (such as parsing and processing large sets of XML data) requires speedy and reliable concurrency.

## Getting ImportElement running on MacOS

Note: I'm happy to jump on a pairing session if you have any issues with setup!

First install Erlang and Elixir.

If you use [asdf](https://asdf-vm.com/) for version management, then `.tool-versions` file contains the Elixir and Erlang versions required.

First add the required plugins:
```
asdf plugin add elixir
asdf plugin add erlang
```
> Note: if you encounter OpenSSL or Java compiler related issues, the [Erlang plugin](https://github.com/asdf-vm/asdf-erlang#osx) may require further configuration.

Then in the repo's root run:
```
asdf install
```

Otherwise, here's where to download each:

- [Erlang](https://www.erlang.org/patches/otp-25.3.2.3)
- [Elixir](https://elixir-lang.org/install.html)

Erlang may take a while to do its thing.

Once they are operational, start the Phoenix server in the repo's root directory:

- Successfully run `mix setup` to install and setup the app's dependencies
- Start the application with `mix phx.server`, or with IEx (Interactive Elixir shell) using `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser to begin the import process.

# Implementation Details

Below details how the ImportElement import and export logic works. The large marjority of this logic lives in the `import_element_live.ex` LiveView component.

## Feature #1 - Importing Payments

1. The element intializes with a file upload imput to prompt the user.
2. LiveView stores a temporary upload of the file.
3. An `import_request` gets created. (This is the main object of the Import Element - each file uploaded equals a new `import_request` and they track the overall progress of the import.)
5. The XML data gets parsed on the backend, and each row of payment data gets persisted into a Postgres database.
   1. there are separate `entity_details`, `account_details`, and `payment_details` tables and schemas that enforce the same associations as the Method API
   2. These locally stored details are only lighted validated prior to upsert (raw-er data is preferred for inevitable debugging purposes)
   3. All records take advantage of the `metadata` field to help query with future response data
7. The element calls the Entities API to create the individuals and corporations.
8. Liability accounts associated to "capable" entities are then individually fed through the Merchant API to obtain the proper merchant_id (via the Plaid ID).
9. All accounts are created via the Accounts API.
10. Payment details for all "capable" accounts are then created (in the app, not the API yet).
11. User is then prompted to approve the total payout.
12. If the user approves the payout, the app then submits all payment details to the Payments API.
13. When the import_request is "finished" the user should see information about the file processing and all entities, accounts, and payments on their Method dashboard.

## Feature #2 - Exporting Reports

1. When an `import_request` is "finished", the app refetches all Payment data from the Payments API. This payment data is used to calculate totals that are then displayed to the user.
2. The payments are grouped by a UUID for the `import_request` (which was stored in the Payment's `metadata` field).
3. CSV reports are generated for the user's imports and can be downloaded.

# What I didn't finish in time

- 3 CSV reports
  - I ran out of time but would've used the UIDs I stored in the payment metadata to further group the import_request's payments
- Calls should be batched for reduced API traffic
  - My plan would've implemented something with Elixir's Supervisor to create a cache of the request count that resets every minute. All requests made the app could access this cache and pause for a minute if the limit is reached.
- User can discard all payment details for an `import_request`
  - I just plain missed this one on all my re-read of the prompt, but implementing a delete or soft delete would've been pretty straightforward.
- Being able to close the app and still have the import process in the background
  - Because I was re-familiarizing myself with LiveView I had to relearn ways to trigger background processing and ended up building just the synchronous/interactive happy path. I would move a lot of the `import_request` flow to a supervisor and async tasks so that processing can continue even when the user disconnects the LiveView socket.

# Future Considerations

- [ ] Better error handling on XML upload (bad param value formatting, XML syntax errors, etc)
- [ ] CSV upload ability (smaller files allow for more volume)
- [ ] Immediately send the XML file to remote storage on the client side
  - compliance considerations:
    - short and long term storage need to meet security standards
    - is there a documented data retention policy in place?
    - determine in advance what data we scrub & retain for business vs hard delete when users request
- [ ] move some work to async jobs or a messaging brokering system if errors increase, users experience timeouts, etc.
- [ ] Retries for failed API calls to the Method API
- [ ] Make the dashboard's endpoints part of Method's public API? (headless option for bulk upload)
- [ ] `import_request.api_user_id` being the Method API user performing the spreadsheet upload (in this case, Dunkies). It should be associated to the API key used and/or `element_token` provided
- [ ] Scan for any idempotency edge cases of `import_request` flow
- [ ] db cleanup when import_requests are not actively working (all uploads complete == empty database)
- [ ] `mix release` to avoid local dev setup headaches
- [ ] Authenticate logged in user via `api_key` or `element_token` request parameter?
