defmodule SMPPEX.PduStorageTest do
  use ExUnit.Case

  alias SMPPEX.PduStorage
  alias SMPPEX.PduStorageSupervisor
  alias SMPPEX.Pdu

  setup_all do
    PduStorageSupervisor.start_link()
    :ok
  end

  setup do
    {pid, process} = PduStorageSupervisor.pdu_storage(SMPPEX.MemSequenceStorage)
    {:ok, %{pid: pid, process: process}}
  end

  test "store", ctx do

    pdu1 = %Pdu{SMPPEX.Pdu.Factory.bind_transmitter("system_id1", "pass1") | sequence_number: 123}
    pdu2 = %Pdu{SMPPEX.Pdu.Factory.bind_transmitter("system_id2", "pass2") | sequence_number: 123}

    assert true == PduStorage.store(ctx.pid, pdu1, 321)
    assert false == PduStorage.store(ctx.pid, pdu2, 321)
    pdus = PduStorage.fetch(ctx.pid, 123)

    assert pdus == [pdu1]
  end

  test "fetch", ctx do

    pdu = %Pdu{SMPPEX.Pdu.Factory.bind_transmitter("system_id", "pass") | sequence_number: 123}

    assert true == PduStorage.store(ctx.pid, pdu, 321)

    assert [pdu] == PduStorage.fetch(ctx.pid, 123)
    assert [] == PduStorage.fetch(ctx.pid, 124)
  end

  test "expire", ctx do
    pdu1 = %Pdu{SMPPEX.Pdu.Factory.bind_transmitter("system_id1", "pass") | sequence_number: 123}
    pdu2 = %Pdu{SMPPEX.Pdu.Factory.bind_transmitter("system_id2", "pass") | sequence_number: 124}

    assert true == PduStorage.store(ctx.pid, pdu1, 1000)
    assert true == PduStorage.store(ctx.pid, pdu2, 2000)

    assert [pdu1] == PduStorage.fetch_expired(ctx.pid, 1500)
    assert [] == PduStorage.fetch(ctx.pid, 123)
    assert [pdu2] == PduStorage.fetch(ctx.pid, 124)
  end

  test "reserve sequence number", ctx do

    SMPPEX.Pdu.Factory.bind_transmitter("system_id", "password")
    reserve_sequence_number  = PduStorage.reserve_sequence_number(ctx.pid)
    assert 1 == reserve_sequence_number
    assert 2 == PduStorage.reserve_sequence_number(ctx.pid)
    assert 3 == PduStorage.reserve_sequence_number(ctx.pid)
    assert 4 == PduStorage.reserve_sequence_number(ctx.pid)

    #Process.exit(ctx.pid, :kill)
    PduStorage.stop(ctx.pid)
    :timer.sleep(1000)
    assert ctx.pid != Process.whereis(ctx.process)

    assert 5 == PduStorage.reserve_sequence_number(ctx.process)

  end

  test "save on every 100 sequence numbers", ctx do

    SMPPEX.Pdu.Factory.bind_transmitter("system_id", "password")
    1..100 |> Enum.to_list |> Enum.each(fn _x -> PduStorage.reserve_sequence_number(ctx.pid) end)
    %{seq_table: seq_table, seq_key: seq_key, seq_store: seq_store} = PduStorage.state(ctx.pid)
    assert 101 == seq_store.get_next_seq(seq_table, seq_key)

  end

  test "isolation", ctx do

    SMPPEX.Pdu.Factory.bind_transmitter("system_id", "password")
    assert 1 == PduStorage.reserve_sequence_number(ctx.pid)
    assert 2 == PduStorage.reserve_sequence_number(ctx.pid)
    assert 3 == PduStorage.reserve_sequence_number(ctx.pid)
    assert 4 == PduStorage.reserve_sequence_number(ctx.pid)

    {pid, _process} = PduStorageSupervisor.pdu_storage()
    assert 1 == PduStorage.reserve_sequence_number(pid)
    assert 2 == PduStorage.reserve_sequence_number(pid)
    assert 3 == PduStorage.reserve_sequence_number(pid)
    assert 4 == PduStorage.reserve_sequence_number(pid)

    assert 5 == PduStorage.reserve_sequence_number(ctx.pid)
    assert 6 == PduStorage.reserve_sequence_number(ctx.pid)
    assert 7 == PduStorage.reserve_sequence_number(ctx.pid)
    assert 8 == PduStorage.reserve_sequence_number(ctx.pid)

  end

end
