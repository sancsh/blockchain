# This is the GenServer Module. 
# It accepts the bitcoin from the workers and prints it out on the server side itself. 
# Also, it performs the task of work allocation i.e. it assigns a new range of numbers(problem range) everytime
# the workers exhaust the work allocated to them.

defmodule BitcoinServer do
  use GenServer

  # Initializes the Server Process
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: BS)
  end 

  # Initializes the Server State
  def init(:ok) do
    {:ok, %{k: 0, x: 0, increment: 1000000}}
  end

  # Set the K value
  def handle_cast({:set_k, value}, state) do
    {:noreply, Map.put(state, :k, value)}
  end

  # Set the number of processes which will be spawned in the workers too
  def handle_cast({:set_process_count, value}, state) do
    {:noreply, Map.put(state,:process_count, value)}
  end
 
  # Set the input string 
  def handle_cast({:set_input_string, value}, state) do
    {:noreply, Map.put(state,:input_string, value)}
  end

  # Prints the bitcoin string at the server side
  def handle_cast({:bitcoin, value}, state) do
    IO.puts value
    {:noreply, state}
  end

  # Provides the range of work to be done by the worker
  def handle_call({:get_increment}, _from, state) do
    {:reply, Map.get(state, :increment), state}
  end

  # Provides the starting value of the new range of numbers(work problems) to be 
  # done by the worker
  def handle_call({:get_new_range}, _from, state) do
    {:reply,Map.get(state,:x),Map.put(state,:x,Map.get(state,:x) + Map.get(state,:increment))}
  end


  def handle_call({:get_state}, _from, state) do
    {:reply, Map.get(state, :x), state}
  end

  # Provides the k number of zeros required to be prefixed in the bitcoin string
  def handle_call({:get_k}, _from, state) do
    {:reply, Map.get(state, :k), state}
  end

  # Provides the input string to the workers
  def handle_call({:get_input_string}, _from, state) do
    {:reply, Map.get(state, :input_string), state}
  end

  # Provides the number of processes to the worker to be spawned by it
  def handle_call({:get_process_count}, _from, state) do
    {:reply, Map.get(state, :process_count), state}
  end  

  #Client APIs

  def printBitcoin(sname, message) do 
    GenServer.cast(sname, {:bitcoin, message})
  end

  def getState(sname) do
    GenServer.call(sname, {:get_state})
  end

  def getNewRange(sname) do 
    GenServer.call(sname, {:get_new_range})
  end

  def getIncrement(sname) do 
    GenServer.call(sname, {:get_increment})
  end

  def getK(sname) do 
    GenServer.call(sname, {:get_k})
  end

  def setK(sname,value) do 
    GenServer.cast(sname, {:set_k, value})
  end

  def getProcessCount(sname) do 
    GenServer.call(sname, {:get_process_count})
  end

  def setProcessCount(sname, value) do 
    GenServer.cast(sname, {:set_process_count, value})
  end

  def getInputString(sname) do 
    GenServer.call(sname, {:get_input_string})
  end

  def setInputString(sname, value) do 
    GenServer.cast(sname, {:set_input_string, value})
  end

end

# This is the main module of the program
defmodule Project1.CLI do
  
  # Command Line arguments are passed in args list
  def main(args \\ []) do
    #IO.inspect Helper.findIP
    
    # If command line argument is an IP address, start a client process 
    if String.match?(List.to_string(args), ~r/[\d]+\.[\d]+\.[\d]+\.[\d]+/) do 
      try do
        cname = String.to_atom ("#{Helper.getRandomName}@#{List.to_string(args)}")
        {resp, _} = Node.start(cname);
        if(resp == :error) do throw "Invalid Node Startup with name: #{cname}" end  
        Node.set_cookie(String.to_atom "fortune")
        sname = String.to_atom ("hbsanc@#{List.to_string args}") 
        result = Node.connect(sname) 
        if result == false do throw "Could not connect to server with server name: #{sname}" end 
        str = WorkerModule.getInputString({BS, sname})
        k =  WorkerModule.getK({BS, sname})
        processCount = WorkerModule.getProcessCount({BS, sname})
        zeroString = String.duplicate("0",k)
        WorkerModule.start({BS, sname}, str,zeroString,processCount)
      catch
        message -> IO.puts "Error Message: #{message}"; exit(:shutdown);
      end
    # If command line argument is a number, start the server 
    else
      try do
        #ipaddr = ""   #	If the code isnt able to find the IP, then hard-code ip here, and uncomment.
        ipaddr = Helper.findIP #If the code fails, hard-code the IP above and comment this line.
        cname = String.to_atom ("hbsanc@#{String.trim ipaddr}")
        str = "hbootwala;kjsdfk";
        processCount = 1000
        {resp, _} = Node.start(cname);
        if(resp == :error) do throw "Invalid Node Startup with name: #{cname}" end  
        Node.set_cookie(String.to_atom "fortune")
        {:ok, _} = BitcoinServer.start_link
        k = String.to_integer List.to_string(args)
        zeroString = String.duplicate("0",k)
        WorkerModule.setInputString({BS, cname}, str)
        WorkerModule.setK({BS, cname}, k)
        WorkerModule.setProcessCount({BS, cname}, processCount)
        WorkerModule.start({BS, cname}, str,zeroString,processCount)
      catch
        message -> IO.puts "Error Message: #{message}"; exit(:shutdown);
      end
   end
  end
end

# This is the worker module. It enables the workers to spanwn processes 
# and listens for messages from the child processes.
defmodule WorkerModule do
  
  # Server Calls
  
  def getK(sname) do
    BitcoinServer.getK(sname);
  end

  def setK(sname, value) do
    BitcoinServer.setK(sname, value)  
  end

  def getInputString(sname) do 
    BitcoinServer.getInputString(sname)
  end

  def setInputString(sname, value) do 
    BitcoinServer.setInputString(sname, value)
  end

  def getProcessCount(sname) do 
    BitcoinServer.getProcessCount(sname)
  end

  def setProcessCount(sname, value) do 
    BitcoinServer.setProcessCount(sname, value)
  end

  # This function gets a starting value and block size from the GenServer.
  # It calls startProcesses, which spawns a fixed number of processes. 
  # After the processes are spawned,
  # it listens for messages received to it from these child processes.
  # Once listen ends i.e. when all the processes have completed their work and exited, 
  # it recursively calls itself to do the same thing.
  
  def start(sname,str,zeroString, processCount) do
    x = GenServer.call(sname, {:get_new_range})
    y = GenServer.call(sname, {:get_increment})
    startProcesses(str,x,y,zeroString, self(), 0, processCount)
    listen(sname,0,processCount)
    start(sname,str,zeroString,processCount)
  end

  # This function listens for messages from the children processes. 
  # If it is a bitcoin string, it will send it to the server and call itself again.
  # If it is a finished message from the child process, 
  # it will call itself by incrementing the process counter(count) variable.
  
  def listen(sname, count, processCount) when count<processCount do
    receive do
      {:bitcoin_string, message} -> BitcoinServer.printBitcoin(sname, message); listen(sname, count, processCount); 
      {:finished} -> listen(sname, count+1, processCount)
    end
  end

  # Once the process counter is equal to the processCount,
  # it will return from this listen function to the start function 
  def listen(_, count, processCount) when count==processCount do
   
  end

  # This function will spawn a new process dividing the main problem assigned to the worker into equitable chunks.
  # Each process will be assigned a single chunk and will continue to work on it until it is exhausted.

  def startProcesses(str, x, y, zeroString, pid, count, processCount) when count<processCount do
    spawn_link(Helper, :mineCoins,[str, zeroString, x, x+(y/processCount)|>round, pid]); 
    startProcesses(str, x+(y/processCount)|>round, y, zeroString, pid, count+1, processCount) 
  end

  # Once all the number of processes have been spawned, 
  # the function will terminate and return to the callee function.

  def startProcesses(_, _, _, _, _, count, processCount) when count == processCount do 
  end
end

# Assists the module in SHA256 computations
defmodule Helper do

  # Finds the IP according to the OS type 
  def findIP do
    {ops_sys, sub_type } = :os.type
    ip = 
    case ops_sys do
     :unix -> 
      case sub_type do
      :darwin ->{:ok, [addr: ip]} = :inet.ifget('en0', [:addr])
                  to_string(:inet.ntoa(ip))
      :linux -> {:ok, [addr: ip]} = :inet.ifget('ens3', [:addr])
                  to_string(:inet.ntoa(ip))
      end           
     :win32 -> {:ok, ip} = :inet.getiflist
     to_string(hd(ip))
    end
    (ip)
  end

  # Returns a random name for the client node name
  # to ensure no naming conflicts would occur.
  def getRandomName do
      hex = :erlang.monotonic_time() |>
        :erlang.phash2(256) |>
        Integer.to_string
  end

  # Calculates the SHA256 string for the given input with the counter appended.
  # If the SHA256 string satisifies the 'k' zeros constraint, 
  # it sends a message containing the stringto the parent process.
  def mineCoins(input, zeroString, count, range, parentId) when count<range do
    shaStr = String.downcase(Base.encode16(:crypto.hash(:sha256, "#{input}#{count}")));
    if String.starts_with?(shaStr, zeroString) == true do
      send(parentId, {:bitcoin_string,"#{input}#{count}     #{shaStr}"}); 
    end 
    mineCoins(input, zeroString, count+1,range, parentId);
  end

  # Once the process has finished its assigned work unit, 
  # it sends a finished message to the parent process.
  def mineCoins(_, _, count, range, parentId) when count >= range do
    send(parentId, {:finished})
  end
end