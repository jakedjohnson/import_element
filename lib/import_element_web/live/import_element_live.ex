defmodule ImportElementWeb.ImportElementLive do
  use ImportElementWeb, :live_view

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

      {:noreply, put_flash(socket, :info, "file #{uploaded_file} uploaded")}
    else
      {:noreply, socket}
    end
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
