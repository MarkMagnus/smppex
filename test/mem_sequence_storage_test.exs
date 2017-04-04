defmodule SMPPEX.MemSequenceStorageTest do
  use ExUnit.Case

  alias SMPPEX.MemSequenceStorage, as: Storage

  setup do
    Storage.start_link
    {table, key} = Storage.init_seq()
    {:ok, %{table: table, key: key}}
  end

  test "store sequence number", ctx do

    assert 1 == Storage.get_next_seq(ctx.table, ctx.key)
    assert 1001 == Storage.save_next_seq(ctx.table, ctx.key, 1001)
    assert 1001 == Storage.get_next_seq(ctx.table, ctx.key)

  end
  
end