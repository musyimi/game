defmodule Gameserver do
  def start() do
    spawn(fn -> listen({1, 30}) end) |>
    Process.register(:game_server)
  end

  defp listen({nil, 0}), do: listen({1,30})
  defp listen({player, current_stones} = current_state) do
    new_state = receive do
       {:take, sender, num_stones} ->
         do_take({sender, player, num_stones, current_stones})

        _ -> current_state
    end

    new_state |> listen #tail call
  end

  defp do_take({sender, player, num_stones_taken, current_stones_count}) when
  not is_integer(num_stones_taken) or
  num_stones_taken < 1 or
  num_stones_taken > 3 or
  num_stones_taken > current_stones_count do
    send sender, {:error, "You can only take 1 to 3 stones, and cannot exceed the total number of stones"}

    {player, current_stones_count}
  end

  defp do_take({sender, player, num_stones_taken, current_stones_count}) when
  num_stones_taken == current_stones_count do
    send sender, {:winner, next_player(player)}

    {nil, 0}
  end


  defp do_take({sender, player, num_stones_taken, current_stones_count}) do
    next = next_player(player)
    new_stones_count = current_stones_count -  num_stones_taken
    send sender, {:next_turn, next, new_stones_count}

    {next, new_stones_count}
  end

  defp next_player(1), do: 2
  defp next_player(2), do: 1

end
