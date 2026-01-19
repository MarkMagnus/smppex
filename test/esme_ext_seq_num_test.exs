defmodule SMPPEX.ESMEExtSeqNumTest do
  use ExUnit.Case

  alias :timer, as: Timer

  alias Support.TCP.Server
  alias Support.ESME, as: SupportESME
  alias SMPPEX.ESME
  alias SMPPEX.Pdu
  alias SMPPEX.PduStorage
  alias SMPPEX.PduStorageSupervisor

  setup do
    server = Server.start_link
    Timer.sleep(50)

    {pdu_storage_pid, pdu_storage_process_name} = PduStorageSupervisor.pdu_storage()

    {callback_backup, esme} = SupportESME.start_link({127,0,0,1}, Server.port(server), [
      enquire_link_limit: 1000,
      enquire_link_resp_limit: 1000,
      inactivity_limit: 10000,
      response_limit: 2000,
      timer_resolution: 100000,
      pool_size: 5,
      pdu_storage_pid: pdu_storage_pid,
      pdu_storage_process_name: pdu_storage_process_name,
    ])

    Timer.sleep(50)

    {:ok, esme: esme, callback_backup: callback_backup, server: server, pdu_storage_pid: pdu_storage_pid}
  end

  test "start_link, with new optional parameters" do
    server = Server.start_link
    Timer.sleep(50)

    {:ok, pid} = Agent.start_link(fn() -> [] end)
    assert {:ok, _} = ESME.start_link({127,0,0,1}, Server.port(server), {SupportESME, %{callbacks: [], callback_backup: pid}})
  end

  test "successfully initiate sequence numbers", ctx do

    pdu = SMPPEX.Pdu.Factory.bind_transmitter("system_id", "password")
    assert Pdu.sequence_number(pdu) == 0

    PduStorage.save_next_sequence_number(ctx.pdu_storage_pid, 100)

    ESME.send_pdu(ctx.esme, pdu)
    Timer.sleep(50)

    assert {:ok, {:pdu, pdu1r}, _rest_data} = Server.received_data(ctx[:server]) |> SMPPEX.Protocol.parse
    assert Pdu.sequence_number(pdu1r) == 100
  end

  test "successfully override sequence number in pdu", ctx do

    pdu1 = SMPPEX.Pdu.Factory.bind_transmitter("system_id", "password")
    pdu1 = %Pdu{pdu1 | sequence_number: 199}
    ESME.send_pdu(ctx[:esme], pdu1)
    Timer.sleep(50)

    assert {:ok, {:pdu, pdu1r}, _rest_data} = Server.received_data(ctx[:server]) |> SMPPEX.Protocol.parse
    assert Pdu.sequence_number(pdu1r) == 199

  end

end