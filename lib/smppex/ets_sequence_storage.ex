defmodule SMPPEX.EtsSequenceStorage do
  @moduledoc """
    This is ets sequence storage service, which allows all running pdu_storage processes share
    sequence numbers and will servive shutdown of the pdu_storage service. If you care about
    sequence number tracking this is all you need.
  """
  @behaviour SMPPEX.SequenceStorage

  use GenServer

  alias :ets, as: ETS

  @default_next_sequence_number 1

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %{}}
  end

  @doc """
    create sequence number table and key
  """
  def init_seq(_params \\ []), do: GenServer.call(__MODULE__, :init_seq)

  @doc """
  returns the next sequence number
  """
  def get_next_seq(seq_table, seq_key), do: GenServer.call(__MODULE__, {:get_next_seq, seq_table, seq_key})

  @doc """
  stores last sequence number
  """
  def save_next_seq(seq_table, seq_key, seq_number) do
    GenServer.call(__MODULE__, {:save_next_seq, seq_table, seq_key, seq_number})
  end

  def handle_call(:init_seq, _from, st) do
    seq_table = ETS.new(:sequence_number, [:set, :protected])
    seq_key = :crypto.strong_rand_bytes(10) |> Base.url_encode64 |> binary_part(0, 10)
    {:reply, {seq_table, seq_key}, st}
  end

  def handle_call({:get_next_seq, seq_table, seq_key}, _from, st) do
    case ETS.lookup(seq_table, seq_key) do
      [] -> {:reply, @default_next_sequence_number, st}
      [{^seq_key, sequence_number}] -> {:reply, sequence_number, st}
    end
  end

  def handle_call({:save_next_seq, seq_table, seq_key, seq_number}, _from, st) do
    :ets.insert(seq_table, {seq_key, seq_number})
    {:reply, seq_number, st}
  end

end