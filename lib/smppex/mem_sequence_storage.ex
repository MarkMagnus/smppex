defmodule SMPPEX.MemSequenceStorage do
  @moduledoc """
    This is the default sequence storage service, which allows all running pdu_storage processes share
    sequence numbers. If you don't care about sequence number tracking this is all you need.
  """
  @behaviour SMPPEX.SequenceStorage

  use GenServer

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

  def state do
    GenServer.call(__MODULE__, :state)
  end

  @doc """
  stores last sequence number
  """
  def save_next_seq(seq_table, seq_key, seq_number) do
    GenServer.call(__MODULE__, {:save_next_seq, seq_table, seq_key, seq_number})
  end

  def handle_call(:init_seq, _from, st) do
    seq_table = :sequence_numbers
    seq_key = :crypto.strong_rand_bytes(10) |> Base.url_encode64 |> binary_part(0, 10)
    {:reply, {seq_table, seq_key}, st}
  end

  def handle_call({:get_next_seq, seq_table, seq_key}, _from, st) do
    seq_number = case st do
      %{ ^seq_table => %{ ^seq_key => seq_number } } -> seq_number
      _ -> @default_next_sequence_number
    end
    {:reply, seq_number, st}
  end

  def handle_call({:save_next_seq, seq_table, seq_key, seq_number}, _from, st) do
    new_st = Map.merge(st, %{ seq_table => %{ seq_key => seq_number}})
    {:reply, seq_number, new_st}
  end

  def handle_call(:state, _from, st) do
    {:reply, st, st}
  end
  
end