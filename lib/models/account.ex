defmodule HighloadCup.Models.Account do
  @moduledoc """
  Модель которая содержит всю информацию о канале связи

  `name` - имя канала, задается администратором
  `type` - тип связи, к которому относится канал. например vk, telegram и т.д.
  `identifier` - уникальный идентификатор канала
  `priority` - приоритет данного канала связи при роутинге активностей
  `config` - хранит конфигурацию канала. Перед созданием канала конфигурацию необходимо задать в файле config/config.exs.
   Имя канала в конфигурации приложения должно совпадать с полем identifier в БД
  """

  alias HighloadCup.Repo

  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field(:email, :string)
    field(:fname, :string)
    field(:sname, :string)
    field(:phone, :string)
    field(:sex, :string)
    field(:birth, :integer)
    field(:country, :string)

    field(:joined, :integer)
    field(:status, :string)
    field(:interests, {:array, :string})
    field(:premium, :map)
    field(:likes, {:array, :map})

    timestamps()
  end

  @cast_fields [
    :email,
    :fname,
    :sname,
    :phone,
    :sex,
    :birth,
    :country,
    :joined,
    :status,
    :interests,
    :premium,
    :likes
  ]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @cast_fields)
  end

  def insert(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> Repo.insert()
  end
end
