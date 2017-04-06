defmodule SMPPEX.PduStorage do
  @moduledoc false

  use GenServer

  require Integer

  alias :ets, as: ETS

  alias SMPPEX.PduStorage
  alias SMPPEX.Pdu

  defstruct [
    :by_sequence_number,
    :next_sequence_number,
    :seq_table,
    :seq_key,
    :seq_store
  ]

  @type t :: %PduStorage{}
  @spec start_link(list, list) :: GenServer.on_start

  def start_link(params \\ [], opts \\ []) do

    params = case params do
      [seq_table: seq_table, seq_key: seq_key, seq_store: seq_store] ->
        Enum.into([seq_table: seq_table, seq_key: seq_key, seq_store: seq_store], %{})
      _ ->
        SMPPEX.MemSequenceStorage.start_link()
        {seq_table, seq_key} = SMPPEX.MemSequenceStorage.init_seq(params)
        Enum.into(params, %{seq_table: seq_table, seq_key: seq_key, seq_store: SMPPEX.MemSequenceStorage})
    end

    GenServer.start_link(__MODULE__, params, opts)
  end

  @spec store(pid, Pdu.t, non_neg_integer) :: boolean

  def store(pid, %Pdu{} = pdu, expire_time) do
    GenServer.call(pid, {:store, pdu, expire_time})
  end

  @spec fetch(pid, non_neg_integer) :: [Pdu.t]

  def fetch(pid, sequence_number) do
    GenServer.call(pid, {:fetch, sequence_number})
  end

  @spec fetch_expired(pid, non_neg_integer) :: [Pdu.t]

  def fetch_expired(pid, expire_time) do
    GenServer.call(pid, {:fetch_expired, expire_time})
  end

  @spec reserve_sequence_number(pid) :: :pos_integer
  @doc """
  Reserve a sequence number by gettingfl current next sequence number and then incrementing.
  Useful if you need to track sequence numbers externally.
  """
  def reserve_sequence_number(pid) do
    GenServer.call(pid, :reserve_sequence_number)
  end

  @spec stop(pid) :: :any
  def stop(pid), do: GenServer.cast(pid, :stop)

  def state(pid), do: GenServer.call(pid, :state)

  def init(params) do

    next_sequence_number = case Map.has_key?(params, :next_sequence_number) do
      true ->
        params.next_sequence_number
      false ->
        params.seq_store.get_next_seq(params.seq_table, params.seq_key)
    end

    Process.flag(:trap_exit, true)
    {:ok, %PduStorage{
      by_sequence_number: ETS.new(:pdu_storage_by_sequence_number, [:set]),
      next_sequence_number: next_sequence_number,
      seq_table: params.seq_table,
      seq_key: params.seq_key,
      seq_store: params.seq_store
    }}
  end

  def handle_cast(:stop, st) do
    raise StopException
    {:noreply, st}
  end

  def handle_call(:state, _from, st), do: {:reply, st, st}

  def handle_call({:store, pdu, expire_time}, _from, st) do
    sequence_number = Pdu.sequence_number(pdu)
    result = ETS.insert_new(st.by_sequence_number, {sequence_number, {expire_time, pdu}})
    {:reply, result, st}
  end

  def handle_call({:fetch, sequence_number}, _from, st) do
    case ETS.lookup(st.by_sequence_number, sequence_number) do
      [{^sequence_number, {_expire_time, pdu}}] ->
        true = ETS.delete(st.by_sequence_number, sequence_number)
        {:reply, [pdu], st}
      [] ->
        {:reply, [], st}
    end
  end

  def handle_call({:fetch_expired, expire_time}, _from, st) do
    expired = ETS.select(st.by_sequence_number, [{ {:'_', {:'$1', :'$2'}}, [{:'<', :'$1', expire_time}], [:'$2']}])
    expired_count = length(expired)
    ^expired_count = ETS.select_delete(st.by_sequence_number, [{ {:'_', {:'$1', :'$2'}}, [{:'<', :'$1', expire_time}], [true]}])
    {:reply, expired, st}
  end

  def handle_call(:reserve_sequence_number, _from, st) do
    new_next_sequence_number = st.seq_store.incr_seq(st.seq_table, st.seq_key, st.next_sequence_number)
    new_st = %PduStorage{st | next_sequence_number: new_next_sequence_number}
    {:reply, st.next_sequence_number, new_st}
  end

  def terminate(_reason, st) do
    st.seq_store.save_next_seq(st.seq_table, st.seq_key, st.next_sequence_number)
  end

  defp increment_sequence_number(st) do
    {st.next_sequence_number, }
  end

end

defmodule StopException do
  defexception message: "stopping process on request"
end

defimpl String.Chars, for: StopException do
  def to_string(exception), do: exception.message
end
