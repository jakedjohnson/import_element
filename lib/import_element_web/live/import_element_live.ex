defmodule ImportElementWeb.ImportElementLive do
  use ImportElementWeb, :live_view
  import SweetXml

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
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
    <form id="upload-form" phx-submit="save" phx-change="validate">
      <div class="container" phx-drop-target={@uploads.file.ref}>
        <label for={@uploads.file.ref}>File</label>
        <.live_file_input upload={@uploads.file} />
      </div>
    </form>
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
      <%= for uploaded_file <- @uploaded_files do %>
        <article class="upload-entry">
          <%= IO.inspect(uploaded_file) %>
        </article>
      <% end %>
    </section>
    """
  end

  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  defp handle_progress(:file, entry, socket) do
    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{path: live_view_upload_path} ->
          destination =
            Path.join([
              :code.priv_dir(:import_element),
              "static",
              "uploads",
              Path.basename(entry.client_name)
            ])

          File.cp!(live_view_upload_path, destination)
          {:ok, ~p"/uploads/#{Path.basename(destination)}"}
        end)

      process_file(uploaded_file)

      {:noreply, put_flash(socket, :info, "file #{uploaded_file} uploaded")}
    else
      {:noreply, socket}
    end
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp process_file(uploaded_file) do
    destination =
      Path.join([
        :code.priv_dir(:import_element),
        "static",
        "uploads",
        Path.basename(uploaded_file)
      ])

    {:ok, xml} = File.read(destination)

    xml
    |> xpath(
      ~x"//root//row"l,
      employee: [
        ~x"./Employee",
        dunkin_id: ~x"./DunkinId/text()"s,
        dunkin_branch: ~x"./DunkinBranch/text()"s,
        first_name: ~x"./FirstName/text()"s,
        last_name: ~x"./LastName/text()"s,
        dob: ~x"./DOB/text()"s,
        phone_number: ~x"./PhoneNumber/text()"s
      ],
      payor: [
        ~x"./Payor",
        dunkin_id: ~x"./DunkinId/text()"s,
        aba_routing: ~x"./ABARouting/text()"s,
        account_number: ~x"./AccountNumber/text()"s,
        name: ~x"./Name/text()"s,
        dba: ~x"./DBA/text()"s,
        ein: ~x"./EIN/text()"s,
        address: [
          ~x"./Address",
          line_1: ~x"./Line1/text()"s,
          city: ~x"./City/text()"s,
          state: ~x"./State/text()"s,
          zip: ~x"./Zip/text()"s
        ]
      ],
      payee: [
        ~x"./Payee",
        plaid_id: ~x"./PlaidId/text()"s,
        loan_account_number: ~x"./LoanAccountNumber/text()"s
      ],
      amount: ~x"./Amount/text()"s
    )
  end
end
