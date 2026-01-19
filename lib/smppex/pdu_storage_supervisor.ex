defmodule SMPPEX.PduStorageSupervisor do
  use Supervisor

  @default_sequnce_storage SMPPEX.MemSequenceStorage

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    childern = [] # initiate childern as required
    supervise childern, strategy: :one_for_one
  end

  @doc """
    instanciate new supervised PDU storage worker and Sequence storage worker
    these work as pair within esme workers
  """
  def pdu_storage(seq_store_module \\ @default_sequnce_storage, seq_store_params \\ []) do

    SMPPEX.PduStorageSupervisor.start_link() # insure supervisor is running
    start_seq_storage(seq_store_module, seq_store_params) # insure chosen sequence number manager is running

    {seq_table, seq_key} = seq_store_module.init_seq(seq_store_params) # get correct sequence store
    pdu_process_name = "pdu_storage_#{seq_table}_#{seq_key}" |> String.to_atom() # name pdu storage unit with respect to sequence store

    pdu_storage_worker_spec = worker(
      SMPPEX.PduStorage,
      [
        [seq_table: seq_table, seq_key: seq_key, seq_store: seq_store_module],
        [name: pdu_process_name],
      ],
      id: pdu_process_name
    )

    {:ok, pdu_storage_pid} = Supervisor.start_child(__MODULE__, pdu_storage_worker_spec)
    {pdu_storage_pid, pdu_process_name}
  end

  def start_seq_storage(seq_store_module, seq_store_params \\ []) do
    seq_storage_worker_spec = worker(seq_store_module, seq_store_params)
    Supervisor.start_child(__MODULE__, seq_storage_worker_spec)
  end

end
