defmodule SMPPEX.PduStorageSupervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    childern = []
    supervise childern, strategy: :one_for_one
  end

  @doc """
    instanciate new supervised PDU storage worker
  """
  def pdu_storage() do
    pdu_storage(SMPPEX.MemSequenceStorage)
  end

  def pdu_storage(seq_store, seq_store_params \\ %{}) do
    seq_storage(seq_store) # only needs to one sequence store of any one type

    {seq_table, seq_key} = seq_store.init_seq(seq_store_params)
    process_name = "pdu_storage_#{seq_table}_#{seq_key}" |> String.to_atom
    pdu_storage_worker_spec = worker(
      SMPPEX.PduStorage,
      [
        [seq_table: seq_table, seq_key: seq_key, seq_store: seq_store],
        [name: process_name],
      ],
      id: process_name
    )
    {:ok, pdu_storage_pid} = Supervisor.start_child(__MODULE__, pdu_storage_worker_spec)
    {pdu_storage_pid, process_name}
  end

  def seq_storage(seq_store) do
    seq_storage_worker_spec = worker(seq_store, [])
    Supervisor.start_child(__MODULE__, seq_storage_worker_spec)
  end
  
end