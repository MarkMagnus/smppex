defmodule SMPPEX.EtsSequenceStorage do
  @moduledoc """
    This is ets sequence storage service, which allows all running pdu_storage processes share
    sequence numbers and will servive shutdown of the pdu_storage service. If you care about
    sequence number tracking this is all you need.
  """
  @behaviour SMPPEX.SequenceStorage

  use GenServer

  alias :ets, as: ETS

  @init_next_sequence_number 1
  @sequence_number_buffer 100

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
    increment next sequence number
  """
  def incr_seq(seq_table, seq_key, seq_number), do: GenServer.call(__MODULE__, {:incr_seq, seq_table, seq_key, seq_number})

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
      [] -> {:reply, @init_next_sequence_number, st}
      [{^seq_key, seq_number}] ->
        next_seq_number = seq_number + @sequence_number_buffer # insure that seq number is never regressed
        ETS.insert(seq_table, {seq_key, next_seq_number})
        {:reply, next_seq_number, st}
    end
  end

  def handle_call({:incr_seq, seq_table, seq_key, seq_number}, _from, st) do
    next_seq_number = seq_number + 1
    cond do
      Integer.mod(next_seq_number, @sequence_number_buffer) == 0 ->
        ETS.insert(seq_table, {seq_key, next_seq_number})
        {:reply, next_seq_number, st}
      true ->
        {:reply, next_seq_number, st}
    end
  end

  def handle_call({:save_next_seq, seq_table, seq_key, seq_number}, _from, st) do
    ETS.insert(seq_table, {seq_key, seq_number})
    {:reply, seq_number, st}
  end

end