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
  alias HighloadCup.Models.Account

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Poison.Encoder, only: [:email, :fname]}

  schema "accounts" do
    field(:email, :string)
    field(:fname, :string)
    field(:sname, :string)
    field(:phone, :string)
    field(:sex, :string)
    field(:birth, :integer)
    field(:country, :string)
    field(:city, :string)

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
    :likes,
    :city
  ]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @cast_fields)
    |> unique_constraint(:email)
    |> unique_constraint(:phone)
  end

  def insert(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> Repo.insert()
  end

  def update(id, params) do
    case Repo.get(Account, id) do
      %Account{} = account ->
        changeset(account, params) |> Repo.update()

      nil ->
        {:error, :not_found}
    end
  end
end
