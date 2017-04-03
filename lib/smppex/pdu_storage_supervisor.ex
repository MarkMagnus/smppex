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
    pdu_storage(SMPPEX.EtsSequenceStorage)
  end

  def pdu_storage(seq_store) do
    seq_storage(seq_store)

    {seq_table, seq_key} = seq_store.init_seq()
    process_name = "pdu_storage_#{seq_key}" |> String.to_atom
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
    seq_storage_worker_spec = worker(SMPPEX.EtsSequenceStorage, [])
    Supervisor.start_child(__MODULE__, seq_storage_worker_spec)
  end
  
end