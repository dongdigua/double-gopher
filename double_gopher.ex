defmodule DoubleGopher do
  # the main part of the server
  require Logger

  def start(port) do
    Agent.start(fn -> :no end, name: :server_state)
    spawn(fn -> __MODULE__.Outer.check_server_loop() end)

    accept(port)
  end

  def accept(port) do
    # TODO: packet: :line work with tls?
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    read_line(socket) |> write_line(socket)
    :gen_tcp.close(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    Logger.info("client: #{inspect(data)}")
    data
  end

  defp write_line(line, socket) do
    output = if Agent.get(:server_state, fn state -> state end) == :ok do
      __MODULE__.Outer.connect_server(line)
    else
      __MODULE__.Inner.run_server(line)
    end
    :gen_tcp.send(socket, output)
  end
end

defmodule DoubleGopher.Inner do
  # act as a tcp wrapper to interact with server
  @server_program "gophernicus/src/gophernicus -d -h localhost -p 7000 -r ."

  def run_server(line) do
    Port.open({:spawn, @server_program}, [:binary])
    |> send({self(), {:command, line}})

    receive do
      {_, {:data, data}} -> data
      _ -> "0 Server Error\r\n"
    end
  end
end


defmodule DoubleGopher.Outer do
  # communicate with outer server (e.g. geomyidae)
  # which may be online or not
  @server_addr {127,0,0,1}
  @server_port 2333
  require Logger

  def check_server() do
    case :gen_tcp.connect(@server_addr, @server_port, [:binary, packet: 0], 100) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        :ok
      {:error, _error} ->
        :no
    end
  end

  def check_server_loop() do
    state = check_server()
    Agent.update(:server_state,
      fn old ->
        cond do
          old == state -> nil
          old == :no -> Logger.info("server online!")
          old == :ok -> Logger.info("server offline!")
        end
          state end)
    Process.sleep(10000)
    check_server_loop()
  end

  def connect_server(line) do
    {:ok, socket} = :gen_tcp.connect(@server_addr, @server_port, [:binary, packet: 0], 100)
    :gen_tcp.send(socket, line)
    loop(socket, "")
  end

  def loop(socket, acc) do
    receive do
      {:tcp, _, data} ->
        loop(socket, acc <> data)
      {:tcp_closed, _} ->
        :gen_tcp.close(socket)
        acc
    end
  end
end

#DoubleGopher.Inner.start_server("\r\n") |> IO.inspect()
DoubleGopher.start(7000)
