defmodule GameClient do
  def play(initial_stones_num \\ 30) do
    GameServer.start(initial_stones_num)
    start_game!()
  end

  defp start_game! do
    send :game_server, {:info, self()}
    recieve do
      {player, current_stones} ->
        IO.puts "Strating the game! It's player #{player} turn.
        There are #{current_stones} stones in the pile."
    end

    take()
  end

  defp stones_to_take({count, _}), do: count
  defp stones_to_take(:error), do: nil

  def ask_stones do
    IO.gets("\nPlease take from 1 to 3 stones from the pile:\n")
    String.trim |>
    Integer.parse |>
    stones_to_take()
  end

  defp take() do
    send :game_server, {:take, self(), ask_stones()}
    recieve do
      {:next_turn, next_player, stones_count} ->
        IO.puts "\nPlayer #{next_player} turns next. Stones #{stones_count}"
        take()
      {:winner, winner} ->
        IO.puts "\nPlayer #{winner} wins!!"
      {:error, reason} ->
        IO.puts "\nThere was an error: #{reason}"
        take()

      after 5000 -> IO.puts :stderr, "Server timeout."
    end
  end
end

defmodule GameServer do
  def start(initial_stones_num) do
    spawn(fn -> listen({1, initial_stones_num}) end) |>
    Process.register(:game_server)
  end

  defp listen({nil, 0}), do: listen({1,30})
  defp listen({player, current_stones} = current_state) do
    new_state = receive do
      {:info, sender} ->
        do_info sender, current_state
       {:take, sender, num_stones} ->
         do_take({sender, player, num_stones, current_stones})

        _ -> current_state
    end

    new_state |> listen #tail call
  end

  defp do_info(sender, current_state) do
    send sender, current_state
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

GameClient.play 10
