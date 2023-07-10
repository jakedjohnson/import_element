defmodule ImportElementWeb.ImportElementLive do
  use ImportElementWeb, :live_view
  import SweetXml

  alias ImportElement.{EntityDetail, ImportRequest, Repo}

  @one_minute 60_000
  @ten_minutes 600_000

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> assign(:import_requests, ImportRequest.all())
     |> assign(:running, false)
     |> assign(:payments, [])
     |> allow_upload(:file,
       accept: ~w(.xml),
       max_file_size: 42_000_000,
       max_entries: 1,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>ImportElement</h1>
    <br />
    <form id="upload-form" phx-submit="save" phx-change="validate">
      <div class="container" phx-drop-target={@uploads.file.ref}>
        <.live_file_input upload={@uploads.file} />
      </div>
    </form>
    <br />
    <section>
      <%= for entry <- @uploads.file.entries do %>
        <article class="upload-entry">
          <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            aria-label="cancel"
          >
            &times;
          </button>

          <%= for err <- upload_errors(@uploads.file, entry) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        </article>
      <% end %>

      <%= for err <- upload_errors(@uploads.file) do %>
        <p class="alert alert-danger"><%= error_to_string(err) %></p>
      <% end %>
    </section>
    <section>
      <%= for import_request <- @import_requests do %>
        <article class="upload-entry">
          <%= inspect(import_request.id) %>
          <%= if import_request.data["totals"] do %>
            <% totals = import_request.data["totals"] %>
            <h4>From XML:</h4>
            <ul>
              <li>Corporations: <%= totals["corporation_count"] || 0 %></li>
              <li>ACH Accounts: <%= totals["ach_count"] || 0 %></li>
              <li>Individuals: <%= totals["individual_count"] || 0 %></li>
              <li>Liability Accounts: <%= totals["liability_count"] || 0 %></li>
              <li>Payments (rows): <%= totals["payment_count"] || 0 %></li>
              <li>Payments total: <%= totals["payment_total"] || 0 %></li>
            </ul>
          <% else %>
            No totals to display.
          <% end %>
          <ul></ul>
        </article>
        <br />
      <% end %>
    </section>
    <%= if @running do %>
      <.spinner />
    <% else %>
      <span class="text-gray-900 font-medium">
        <%= if @payments, do: "#{@payments} rows", else: "?" %>
      </span>
    <% end %>
    """
  end

  defp spinner(assigns) do
    ~H"""
    <svg
      phx-no-format
      class="inline mr-2 w-4 h-4 text-gray-200 animate-spin fill-blue-600"
      viewBox="0 0 100 101"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor" />
      <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill" />
    </svg>
    """
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  defp handle_progress(:file, entry, socket) do
    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{path: live_view_upload} ->
          destination =
            Path.join([
              :code.priv_dir(:import_element),
              "static",
              "uploads",
              Path.basename(entry.client_name)
            ])

          File.cp!(live_view_upload, destination)
          {:ok, ~p"/uploads/#{Path.basename(destination)}"}
        end)

      import_request = start_import_request(uploaded_file)
      import_requests = [import_request | socket.assigns.import_requests]

      {:noreply,
       socket
       |> put_flash(:info, "#{import_request.file} uploaded")
       |> assign(import_requests: import_requests)
       |> assign(current_step: import_request.status)
       |> assign(running: true)}
    else
      {:noreply, socket}
    end
  end

  defp start_import_request(uploaded_file) do
    import_request = ImportRequest.create(%{file: uploaded_file})
    Task.async(fn -> parse_xml(import_request) end)
    import_request
  end

  defp parse_xml(import_request) do
    import_request = ImportRequest.update_request(import_request, %{status: "parsing_xml"})

    destination =
      Path.join([
        :code.priv_dir(:import_element),
        "static",
        "uploads",
        Path.basename(import_request.file)
      ])

    {:ok, xml} = File.read(destination)

    data =
      xml
      |> xpath(
        ~x"//root//row"l,
        amount: ~x"./Amount/text()"s,
        source: [
          ~x"./Payor",
          entity: [
            ~x".",
            corporation: [
              ~x".",
              name: ~x"./Name/text()"s,
              dba: ~x"./DBA/text()"s,
              ein: ~x"./EIN/text()"s
            ],
            address: [
              ~x"./Address",
              line1: ~x"./Line1/text()"s,
              city: ~x"./City/text()"s,
              state: ~x"./State/text()"s,
              zip: ~x"./Zip/text()"s
            ]
          ],
          account: [
            ~x".",
            ach: [
              ~x".",
              routing: ~x"./ABARouting/text()"s,
              number: ~x"./AccountNumber/text()"s
            ],
            metadata: [
              ~x".",
              dunkin_id: ~x"./DunkinId/text()"s
            ]
          ]
        ],
        destination: [
          ~x".",
          entity: [
            ~x".",
            individual: [
              ~x"./Employee",
              first_name: ~x"./FirstName/text()"s,
              last_name: ~x"./LastName/text()"s,
              dob: ~x"./DOB/text()"s,
              phone: ~x"./PhoneNumber/text()"s
            ],
            metadata: [
              ~x"./Employee",
              dunkin_id: ~x"./DunkinId/text()"s,
              dunkin_branch: ~x"./DunkinBranch/text()"s
            ]
          ],
          account: [
            ~x".",
            liability: [
              ~x"./Payee",
              number: ~x"./LoanAccountNumber/text()"s
            ],
            metadata: [
              ~x"./Payee",
              plaid_id: ~x"./PlaidId/text()"s
            ]
          ]
        ],
        metadata: [
          ~x".",
          dunkin_employee: ~x"./Employee/DunkinId/text()"s,
          dunkin_branch: ~x"./Employee/DunkinBranch/text()"s,
          source_account: ~x"./Payor/DunkinId/text()"s
        ]
      )

    %{
      next_step: :process_file,
      import_request: import_request,
      data: data
    }
  end

  defp process_file(import_request, data) do
    data
    |> Enum.each(fn %{
                      amount: amount,
                      destination: %{
                        entity: %{
                          individual: individual,
                          metadata: individual_metadata
                        },
                        account: %{
                          liability: liability,
                          metadata: liability_metadata
                        }
                      },
                      source: %{
                        account: %{
                          ach: ach,
                          metadata: ach_metadata
                        },
                        entity: %{
                          corporation: corporation,
                          address: corporate_address
                        }
                      },
                      metadata: payment_metadata
                    } ->
      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :individual,
        EntityDetail.changeset(%{
          import_request_id: import_request.id,
          type: "individual",
          uid: individual_metadata.dunkin_id,
          data: %{
            type: "individual",
            individual: individual,
            metadata: individual_metadata
          }
        }),
        on_conflict: [set: [updated_at: DateTime.utc_now()]],
        conflict_target: [:import_request_id, :uid, :type],
        returning: true
      )
      |> Ecto.Multi.insert(
        :corporation,
        EntityDetail.changeset(%{
          import_request_id: import_request.id,
          type: "corporation",
          uid: corporation.ein,
          data: %{
            type: "llc",
            corporation: Map.put(corporation, :owners, []),
            address: corporate_address
          }
        }),
        on_conflict: [set: [updated_at: DateTime.utc_now()]],
        conflict_target: [:import_request_id, :uid, :type],
        returning: true
      )
      |> Ecto.Multi.insert(
        :destination,
        fn %{individual: individual} ->
          Ecto.build_assoc(
            individual,
            :account_details,
            %{
              import_request_id: individual.import_request_id,
              entity_detail_id: individual.id,
              type: "liability",
              uid: liability.number,
              data: %{
                liability: liability,
                metadata: liability_metadata
              }
            }
          )
        end,
        on_conflict: [set: [updated_at: DateTime.utc_now()]],
        conflict_target: [:entity_detail_id, :uid, :type],
        returning: true
      )
      |> Ecto.Multi.insert(
        :source,
        fn %{corporation: corporation} ->
          Ecto.build_assoc(
            corporation,
            :account_details,
            %{
              import_request_id: corporation.import_request_id,
              entity_detail_id: corporation.id,
              type: "ach",
              uid: ach_metadata.dunkin_id,
              data: %{
                ach: Map.put(ach, :type, "checking"),
                metadata: ach_metadata
              }
            }
          )
        end,
        on_conflict: [set: [updated_at: DateTime.utc_now()]],
        conflict_target: [:entity_detail_id, :uid, :type],
        returning: true
      )
      |> Ecto.Multi.insert(
        :payment,
        fn %{destination: liability, source: ach} ->
          ImportElement.PaymentDetail.changeset(%{
            import_request_id: import_request.id,
            source_id: ach.id,
            destination_id: liability.id,
            data: %{
              amount: amount,
              metadata: payment_metadata
            }
          })
        end
      )
      |> Repo.transaction()
    end)

    %{
      next_step: :api_sync,
      import_request: import_request,
      data: %{
        totals: ImportElement.ImportRequest.totals(import_request.id)
      }
    }
  end

  defp sync_api(import_request) do
    entities_needing_sync = EntityDetail.all_for_import_request(import_request.id)

    capable_entities =
      entities_needing_sync
      |> Task.async_stream(
        fn %{data: entity_params} = entity_detail ->
          formatted_params = ImportElement.MethodApi.Entity.format_params(entity_params)
          resp = ImportElement.MethodApi.Entity.create(formatted_params)
          entity_detail = ImportElement.EntityDetail.sync_method_response(entity_detail, resp)
          {resp, entity_detail}
        end,
        max_concurrency: 1,
        timeout: @one_minute,
        ordered: false
      )
      |> Enum.to_list()
      |> Enum.reduce([], fn {_task_result, {_resp, entity}}, acc ->
        if entity.capable do
          entity = Repo.preload(entity, [:account_details])
          [entity | acc]
        end
      end)
      |> List.flatten()

    capable_accounts =
      capable_entities
      |> Task.async_stream(
        fn %{account_details: [%{data: account_params} = account_detail]} = entity ->
          {:ok, account_detail} =
            if account_detail.type == "liability" do
              [merchant] = ImportElement.MethodApi.Merchant.find(account_params)
              ImportElement.AccountDetail.sync_merchant(account_detail, merchant)
            else
              {:ok, account_detail}
            end

          formatted_params = ImportElement.MethodApi.Account.format_params(entity, account_detail)
          resp = ImportElement.MethodApi.Account.create(formatted_params)
          {:ok, account_detail} = ImportElement.AccountDetail.sync_method_response(account_detail, resp)

          {resp, account_detail}
        end,
        max_concurrency: 1,
        timeout: @one_minute,
        ordered: false
      )
      |> Enum.to_list()


    capable_accounts
    |> Enum.map(fn {_task_result, {_resp, account_detail}} ->
      {payment_details, data} =
        if account_detail.type == "ach" do
          outgoing_payments = Repo.preload(account_detail, [:outgoing_payments]).outgoing_payments
          {outgoing_payments, %{"source_id" => account_detail.method_id}}
        else
          incoming_payments = Repo.preload(account_detail, [:incoming_payments]).incoming_payments
          {incoming_payments, %{"destination_id" => account_detail.method_id}}
        end

      ImportElement.PaymentDetail.batch_merge_data(payment_details, data)
    end)

    # now all payments should be "ready" (if ready)

    ready_payment_count = ImportElement.PaymentDetail.ready_count(import_request.id)
    ready_payment_total = ImportElement.PaymentDetail.ready_total(import_request.id)

    %{next_step: :awaiting_approval}
  end

  ### "State machine" / import request flow management

  def handle_info({ref, %{next_step: :process_file} = message}, socket) do
    end_task(ref)
    status = "processing_file"
    import_request = ImportRequest.update_request(message.import_request, %{status: status})
    Task.async(fn -> process_file(import_request, message.data) end)
    {:noreply, assign(socket, running: true, current_step: status)}
  end

  def handle_info(
        {ref, %{next_step: :api_sync, import_request: import_request, data: data}},
        socket
      ) do
    end_task(ref)
    status = "api_aync"
    import_request = ImportRequest.update_request(import_request, %{status: status})
    import_request = ImportRequest.update_request_data(import_request, data)
    Task.async(fn -> sync_api(import_request) end)

    {:noreply,
     assign(socket, running: true, current_step: status, import_requests: ImportRequest.all())}
  end

  # catch all for unexpected messages
  def handle_info({ref, _result}, socket) do
    Process.demonitor(ref, [:flush])
    {:noreply, assign(socket, running: false, current_step: "unknown?")}
  end

  defp end_task(ref), do: Process.demonitor(ref, [:flush])
end
