module App

using GenieFramework, Turby
@genietools

import PlotlyBase, PlotlyKaleido, Plots
Plots.plotly()

#helper function to make the plot
function mkplot(x,y)
    p = Plots.scatter(x./1000,y,
                      xlabel="time (s)",ylabel="turbidity (au)",
                      grid=false, legend=false)
    (Plots.plotly_traces(p), Plots.plotly_layout(p))
end

(pt, pl) = mkplot([],[])

@app begin
    @in load = false
    @in run = false
    @in stop = false
    @in notrun = true
    #Vector of [time,turb] vectors
    @private datapoints = []
    @private channel = Channel(8)
    @out traces = pt
    @out layout = pl
    @onbutton load begin
        td = ENV["TURBYDIR"]
        cd(ENV["TURBYDIR"]) do
            loadposition()
        end
    end
    @onbutton stop begin
        close(channel)
    end
    @onchange run begin
        notrun = !run
        #if we're switching run to false don't run the rest
        if !run
            return
        end
        channel = Channel(8)
        @async begin
            cd(ENV["TURBYDIR"]) do
                dissociate(channel)
            end
        end
        @async begin
            #until the channel is closed
            while true
                try
                    newturb = take!(channel)
                    datapoints = vcat(datapoints,newturb)
                catch e
                    #the channel was closed
                    break
                end
            end
            run = false
            println("ending consumer async")
        end
    end
    @onchange datapoints begin
        times = [dp[1] for dp in datapoints]
        turbs = [dp[2] for dp in datapoints]
        (traces,layout) = mkplot(times,turbs)
    end
end
    
function ui()
    loadbutton = btn("load position",@click("load = true"),loading=:run)
    runbutton = btn("run",@click("run = true"),loading = :run)
    stopbutton = btn("stop",@click("stop = true"),loading =:notrun)
    p = plot(:traces,layout=:layout)
    [cell([loadbutton, runbutton, stopbutton]),
     cell([p])]
end

@page("/",ui)

end # module TurbyGUI
