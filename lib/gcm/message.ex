defmodule GCM.Message do
  defstruct [
    id: nil,
    notification: nil,
    data: [],
  ]

  def new do
    make_ref |> :erlang.phash2 |> new
  end

  def new(id) do
    %__MODULE__{id: id}
  end

  defmodule Notification do
    defstruct [
      title: "",
      body: "",
      icon: nil,
      sound: "default",
      title_loc_key: nil,
      title_loc_args: nil,
      action_loc_key: nil,
      body_loc_key: "",
      body_loc_args: [],
      launch_image: nil
    ]
  end
end
