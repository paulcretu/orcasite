defmodule OrcasiteWeb.Resolvers.Detection do
  alias Orcasite.Radio
  alias OrcasiteWeb.Paginated

  def index(_, %{context: %{current_user: %{admin: true}}}) do
    {:ok, Radio.list_detections()}
  end

  def index(_, _), do: {:error, :not_authorized}

  def list_candidates(args, %{context: %{current_user: %{admin: true}}}) do
    {:ok, Paginated.format(Radio.list_candidates(args))}
  end

  def list_candidates(_, _), do: {:error, :not_authorized}

  def create(
        %{
          feed_id: feed_id,
          playlist_timestamp: _playlist_timestamp,
          player_offset: _player_offset
        } = detection_attrs,
        %{context: %{remote_ip: remote_ip}}
      ) do
    # Store new detection
    source_ip =
      remote_ip
      |> :inet_parse.ntoa()
      |> to_string()

    with :ok <- Radio.verify_can_submit_detection(feed_id, source_ip, lockout_seconds()) do
      detection_attrs
      |> Map.put(:source_ip, source_ip)
      |> Radio.create_detection_with_candidate()
      |> case do
        {:ok, detection} ->
          {:ok,
           %{
             detection: detection,
             lockout_initial: lockout_seconds(),
             lockout_remaining: lockout_seconds()
           }}

        {:error, _} ->
          {:error, :invalid}
      end
    else
      {:error, %{lockout_remaining: lockout_remaining}} ->
        {:error,
         %{
           message: "lockout",
           details: %{lockout_remaining: lockout_remaining, lockout_initial: lockout_seconds()}
         }}

      error ->
        error
    end
  end

  def submit(_, _), do: {:error, :invalid}

  # TODO: Define this as an env var
  defp lockout_seconds(), do: 10
end
