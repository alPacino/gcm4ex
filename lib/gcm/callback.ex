defmodule GCM.Callback do
  require Logger

  def error(%GCM.Error{error: error, message_id: message_id}) do
    Logger.error "[GCM] Error \"#{error}\" for message #{inspect message_id}"
  end
  def feedback(%GCM.Feedback{token: token}) do
    Logger.info "[GCM] Feedback received for token #{token}"
  end
end