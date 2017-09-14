defmodule BitcoinServer do
  use GenServer

  def start_link(opts \\[]) do
    GenServer.start_link(__MODULE__, :ok, name: BS)
  end 

  def init(:ok) do
    {:ok, %{x: 0, increment: 200000}}
  end

  def handle_cast({:bitcoin, value}, state) do
    IO.puts value
    {:noreply, state}
  end

  def handle_call({:get_increment}, _from, state) do
    {:reply, Map.fetch(state, :increment), state}
  end

  def handle_call({:get_new_range}, _from, state) do
    {:reply,Map.fetch(state,:x),Map.put(state,:x,Map.get(state,:x) + Map.get(state,:increment))}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, Map.fetch(state, :x), state}
  end

  def printBitcoin(message) do 
    GenServer.cast(BS, {:bitcoin, message})
  end

  def getState do
    GenServer.call(BS, {:get_state})
  end

  def getNewRange do 
    GenServer.call(BS, {:get_new_range})
  end

  def getIncrement do 
    GenServer.call(BS, {:get_increment})
  end
end


defmodule Project1.CLI do
  
  def main(args \\ []) do
    # Do stuff

    
     # tuple = elem(elem(List.pop_at(elem(elem(List.pop_at(elem(:inet.getifaddrs,1),3),0),1),4),0),1)
     # IO.puts :inet.ntoa(tuple)

    
    if String.contains?(List.to_string(args), ".") == true do 
      Node.start(String.to_atom("fo@10.136.177.38"));
      Node.set_cookie(String.to_atom "monster")
      Node.connect(String.to_atom "one@10.136.103.178")  
      str = "hbootwala;kjsdfk";
      zeroString = String.duplicate("0",7);
      #IO.inspect GenServer.call({BS, String.to_atom "one@192.168.0.12"}, {:get_state})
      ExternalClientCode.call({BS, String.to_atom("one@10.136.103.178")}, str,zeroString)
    else
      # {elemnt,list} = List.pop_at(elem(:inet.getifaddrs,1),2);
      # {addr,_} = List.pop_at(elem(elemnt,1),7);
     # IPAddr = String.to_atom("one@10.136.103.178");
      Node.start(String.to_atom("one@10.136.103.178"));
      Node.set_cookie(String.to_atom "monster")
      {:ok, pid} = BitcoinServer.start_link
      str = "hbootwala;kjsdfk";
      #k = String.to_integer List.to_string(args);
      zeroString = String.duplicate("0",7);
      ExternalClientCode.call({BS, String.to_atom("one@10.136.103.178")}, str,zeroString)
   end
  end
end


defmodule ExternalClientCode do
  def call(sname,str,zeroString) do
    {:ok, x} = GenServer.call(sname, {:get_new_range})
    {:ok, y} = GenServer.call(sname, {:get_increment})
    count = 0;
    IO.puts x
    startProcesses(str,x,y,zeroString, self(), 0)
    listen(sname,count)
    call(sname,str,zeroString)
  end

  def listen(sname,count) when count<500 do
    receive do
      {:ok, message} -> GenServer.cast(sname, {:bitcoin,message}); listen(sname, count); 
      {:finished} -> listen(sname, count+1)
    end
    

  end

  def listen(sname,count) when count>=500 do
    
  end

  def startProcesses(str,x,y,zeroString,pid,processCount) when processCount<500 do
    spawn(Helper,:processMineCoins,[str,x,x+(y/100)|>round,zeroString,pid]); 
    startProcesses(str,x+(y/100)|>round,y,zeroString,pid, processCount+1) 
  end

  def startProcesses(str,x,y,zeroString,pid, processCount) when processCount == 500 do 
  end
end

defmodule Helper do
  def processMineCoins(str,count,range, zeroString, parentId) do
    mineCoins(str, zeroString, count, range,parentId);   
  end

def mineCoins(input, zeroString, count, range, parentId) when count<range do
  shaStr = String.downcase(Base.encode16(:crypto.hash(:sha256, "#{input}#{count}")));
  if String.starts_with?(shaStr, zeroString) == true do
    send(parentId, {:ok,"SANCHIT#{input}#{count}     #{shaStr}"}); 

  end 
  mineCoins(input, zeroString, count+1,range, parentId);
end

def mineCoins(input, zeroString, count, range, parentId) when count >= range do
  send(parentId, {:finished})
end

end


# defmodule ClientCode do
#   def call(str,zeroString) do
#     {:ok, x} = BitcoinServer.getNewRange;
#     {:ok, y} = BitcoinServer.getIncrement;
#     count = 0;
#     startProcesses(str,x,y,zeroString, self(), 0)
#     listen(count)
#     call(str,zeroString)
#   end

#   def listen(count) when count<=9 do
#     receive do
#       {:ok, message} -> BitcoinServer.printBitcoin(message); listen(count); 
#       {:finished} -> listen(count+1)
#     end
    

#   end

#   def listen(count) when count>=10 do
    
#   end

#   def startProcesses(str,x,y,zeroString,pid,processCount) when processCount<100 do
#     spawn(Helper,:processMineCoins,[str,x,x+(y/10)|>round,zeroString,pid]); 
#     startProcesses(str,x+(y/100)|>round,y,zeroString,pid, processCount+1) 
#   end

#   def startProcesses(str,x,y,zeroString,pid, processCount) when processCount == 100 do 
#   end
# end

# defmodule Helper do
#   def processMineCoins(str,count,range, zeroString, parentId) do
#     mineCoins(str, zeroString, count, range,parentId);   
#   end

# def mineCoins(input, zeroString, count, range, parentId) when count<range do
#   shaStr = String.downcase(Base.encode16(:crypto.hash(:sha256, "#{input}#{count}")));
#   if String.starts_with?(shaStr, zeroString) == true do
#     send(parentId, {:ok,"#{input}#{count}     #{shaStr}"}); 

#   end 
#   mineCoins(input, zeroString, count+1,range, parentId);
# end

# def mineCoins(input, zeroString, count, range, parentId) when count >= range do
#   send(parentId, {:finished})
# end

# end
