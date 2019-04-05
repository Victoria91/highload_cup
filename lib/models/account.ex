defmodule HighloadCup.Models.Account do
  alias HighloadCup.Repo
  alias HighloadCup.Models.Account

  use Ecto.Schema
  import Ecto.Changeset

  import EctoEnum
  defenum StatusEnum, :status, ["свободны", "заняты", "всё сложно"]

  # @derive {Poison.Encoder, only: [:email, :id, :status, :fname, :sname]}

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
    field(:status, StatusEnum)
    field(:interests, {:array, :string})
    field(:premium, :map)
    field(:likes, :string)

    # timestamps()
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
    :city,
    :id
  ]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @cast_fields)
    |> validate_format(:email, ~r/@/)
    |> validate_inclusion(:sex, ["f", "m"])
    # |> validate_inclusion(:status, ["свободны", "заняты", "всё сложно"])
    |> unique_constraint(:email)
    |> unique_constraint(:phone)
  end

  def changeset_without_validations(struct, params \\ %{}) do
    struct
    |> cast(params, @cast_fields)
  end

  def insert(%{} = params, skip_validations: true) do
    %__MODULE__{}
    |> changeset_without_validations(params)
    |> Repo.insert()
  end

  def insert(%{"likes" => likes} = params) when is_list(likes) do
    %{params | "likes" => Jason.encode!(likes)} |> insert
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
