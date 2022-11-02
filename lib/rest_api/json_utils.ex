defmodule RestApi.JsonUtils do
  @moduledoc """
  JSON Utilities
  """

  defimpl Jason.Encoder, for: BSON.ObjectId do
    def encode(id, options) do
      BSON.ObjectId.encode!(id)
      |> Jason.Encoder.encode(options)
    end
  end

  def normalizeMongoId(doc) do
    doc
    |> Map.put('id', doc["_id"])
    |> Map.delete("_id")
  end
end
