export view_header

"""
    header(obj)

Show keys and values of OBJ header.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
"""
function view_header(obj::NeuroAnalyzer.NEURO)
    
    f = string(fieldnames(typeof(obj.header)))
    f = replace(f, "("=>"", ")"=>"", ":"=>"")
    println("Header fields: $f")
    for (key, value) in obj.header.subject
        println("header.subject[:$key]: $value")
    end
    for (key, value) in obj.header.recording
        println("header.recording[:$key]: $value")
    end
    for (key, value) in obj.header.experiment
        println("header.experiment[:$key]: $value")
    end
    println("header.component_names: $(obj.header.component_names)")
    println("header.history: $(obj.header.history)")

end
