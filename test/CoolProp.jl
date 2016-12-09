module CoolProp
using Compat
export PropsSI, PhaseSI, get_global_param_string, get_parameter_information_string,get_fluid_param_string,set_reference_stateS, get_param_index, get_input_pair_index, set_config, F2K, K2F, HAPropsSI, AbstractState_factory, AbstractState_free, AbstractState_set_fractions, AbstractState_update, AbstractState_specify_phase, AbstractState_unspecify_phase, AbstractState_keyed_output, AbstractState_output, AbstractState_update_and_common_out, AbstractState_update_and_1_out, AbstractState_update_and_5_out, AbstractState_set_binary_interaction_double, AbstractState_set_cubic_alpha_C, AbstractState_set_fluid_parameter_double

errcode = Ref{Clong}(0)

const buffer_length = 20000
message_buffer = Array(UInt8, buffer_length)

const inputs_to_get_global_param_string = ["version", "gitrevision", "errstring", "warnstring", "FluidsList", "incompressible_list_pure", "incompressible_list_solution", "mixture_binary_pairs_list", "parameter_list", "predefined_mixtures", "HOME", "cubic_fluids_schema"];

# ---------------------------------
#        High-level functions
# ---------------------------------

"""
    PropsSI(fluid::AbstractString, output::AbstractString)

Return a value that does not depend on the thermodynamic state - this is a convenience function that does the call `PropsSI(output, "", 0, "", 0, fluid)`.

# Example
```julia

```
# Arguments
* `fluid`: The name of the fluid that is part of CoolProp, for instance "n-Propane", to get a list of different passible fulid types call `get_global_param_string(key)` with `key` on of the following: `["FluidsList", "incompressible_list_pure", "incompressible_list_solution", "mixture_binary_pairs_list", "predefined_mixtures"]`, also there is a list in CoolProp online documentation [List of Fluids](http://www.coolprop.org/fluid_properties/PurePseudoPure.html#list-of-fluids)
* `output`: 
# Ref
CoolProp::Props1SI(std::string, std::string)
"""
function PropsSI(fluid::AbstractString, output::AbstractString)
  val = ccall( (:Props1SI, "CoolProp"), Cdouble, (Ptr{UInt8}, Ptr{UInt8}), fluid, output)
  if val == Inf
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return val
end

"""
    PropsSI(output::AbstractString, name1::AbstractString, value1::Real, name2::AbstractString, value2::Real, fluid::AbstractString)

Return a value that depends on the thermodynamic state.

# Ref
CoolProp::PropsSI(const std::string &, const std::string &, double, const std::string &, double, const std::string&)
# Arguments
* `fluid`: The name of the fluid that is part of CoolProp, for instance "n-Propane", to get a list of different passible fulid types call `get_global_param_string(key)` with `key` on of the following: `["FluidsList", "incompressible_list_pure", "incompressible_list_solution", "mixture_binary_pairs_list", "predefined_mixtures"]`, also there is a list in CoolProp online documentation [List of Fluids](http://www.coolprop.org/fluid_properties/PurePseudoPure.html#list-of-fluids)
"""
function PropsSI(output::AbstractString, name1::AbstractString, value1::Real, name2::AbstractString, value2::Real, fluid::AbstractString)
  val = ccall( (:PropsSI, "CoolProp"), Cdouble, (Ptr{UInt8}, Ptr{UInt8}, Float64, Ptr{UInt8}, Float64, Ptr{UInt8}), output, name1, value1, name2, value2, fluid)
  if val == Inf
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return val
end

"""
    PhaseSI(Name1::AbstractString, Value1::Real, Name2::AbstractString, Value2::Real, Fluid::AbstractString)

Return a string representation of the phase.

\ref CoolProp::PhaseSI(const std::string &, double, const std::string &, double, const std::string&)
\note This function returns the phase string in pre-allocated phase variable.  If buffer is not large enough, no copy is made
"""
function PhaseSI(Name1::AbstractString, Value1::Real, Name2::AbstractString, Value2::Real, Fluid::AbstractString)
  val = ccall( (:PhaseSI, "CoolProp"), Int32, (Ptr{UInt8},Float64,Ptr{UInt8},Float64,Ptr{UInt8}, Ptr{UInt8}, Int), Name1,Value1,Name2,Value2,Fluid,message_buffer::Array{UInt8,1},buffer_length)
  val = unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer::Array{UInt8,1})))
  if val == ""
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return val
end
"""
    get_global_param_string(key::AbstractString)

Get a globally-defined string.

# Ref
ref CoolProp::get_global_param_string
# Arguments
* `key`: A string represents parameter name, could be one of $inputs_to_get_global_param_string
"""
function get_global_param_string(key::AbstractString)
  val = ccall( (:get_global_param_string, "CoolProp"), Clong, (Ptr{UInt8},Ptr{UInt8},Int), key, message_buffer::Array{UInt8,1}, buffer_length)
  if val == 0
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer::Array{UInt8,1})))
end

"""
    get_parameter_information_string(key::AbstractString,outtype::AbstractString)
    get_parameter_information_string(key::AbstractString)

Get information for a parameter.

# Arguments

* `key`: A string represents parameter name, to see full list check "Table of string inputs to PropsSI function": http://www.coolprop.org/coolprop/HighLevelAPI.html#parameter-table
* `outtype="long"`: Output type, could be one of the `["IO", "short", "long", "units"]`, with a default value of "long"

# Example
```julia
julia> get_parameter_information_string("HMOLAR")
"Molar specific enthalpy"

julia> get_parameter_information_string("HMOLAR", "units")
"J/mol"
```
# Note
This function return the output string in pre-allocated char buffer.  If buffer is not large enough, no copy is made

"""
function get_parameter_information_string(key::AbstractString,outtype::AbstractString)
  message_buffer[1:length(outtype)+1] = [outtype.data; 0x00]
  val = ccall( (:get_parameter_information_string, "CoolProp"), Clong, (Ptr{UInt8},Ptr{UInt8},Int), key,message_buffer::Array{UInt8,1},buffer_length)
  if val == 0
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer::Array{UInt8,1})))
end

function get_parameter_information_string(key::AbstractString)
  return get_parameter_information_string(key,"long")
end

"""
    get_fluid_param_string(fluid::AbstractString,param::AbstractString)

Get a string for a value from a fluid (numerical values for the fluid can be obtained from Props1SI function).

# Arguments

* `fluid`: The name of the fluid that is part of CoolProp, for instance "n-Propane"
* `param`: A string, can be in one of the terms described in the following table


    ParamName                    | Description
    --------------------------   | ----------------------------------------
    "aliases"                    | A comma separated list of aliases for the fluid
    "CAS", "CAS_number"          | The CAS number
    "ASHRAE34"                   | The ASHRAE standard 34 safety rating
    "REFPROPName","REFPROP_name" | The name of the fluid used in REFPROP
    "Bibtex-XXX"                 | A BibTeX key, where XXX is one of the bibtex keys used in get_BibTeXKey
    "pure"                       | "true" if the fluid is pure, "false" otherwise
    "formula"                    | The chemical formula of the fluid in LaTeX form if available, "" otherwise

"""
function get_fluid_param_string(fluid::AbstractString,param::AbstractString)
  val = ccall( (:get_fluid_param_string, "CoolProp"), Clong, (Ptr{UInt8},Ptr{UInt8},Ptr{UInt8},Int), fluid,param,message_buffer::Array{UInt8,1},buffer_length)
  if val == 0
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer::Array{UInt8,1})))
end

"""
    set_config(key::AbstractString, val::AbstractString)

\brief Set configuration string
@param key The key to configure
@param val The value to set to the key
\note you can get the error message by doing something like get_global_param_string("errstring",output)
ALTERNATIVE_TABLES_DIRECTORY, "ALTERNATIVE_TABLES_DIRECTORY", "", "If provided, this path will be the root directory for the tabular data.  Otherwise, \${HOME}/.CoolProp/Tables is used"
ALTERNATIVE_REFPROP_PATH, "ALTERNATIVE_REFPROP_PATH", "", "An alternative path to be provided to the directory that contains REFPROP's fluids and mixtures directories.  If provided, the SETPATH function will be called with this directory prior to calling any REFPROP functions."
ALTERNATIVE_REFPROP_HMX_BNC_PATH, "ALTERNATIVE_REFPROP_HMX_BNC_PATH", "", "An alternative path to the HMX.BNC file.  If provided, it will be passed into REFPROP's SETUP or SETMIX routines"
VTPR_UNIFAQ_PATH, "VTPR_UNIFAQ_PATH", "", "The path to the directory containing the UNIFAQ JSON files.  Should be slash terminated"
"""
function set_config(key::AbstractString, val::AbstractString)
  ccall( (:set_config_string, "CoolProp"), Void, (Ptr{UInt8},Ptr{UInt8}), key,val)
  return get_global_param_string("errstring")
end

"""
    set_config(key::AbstractString, val::Real)

\brief Set configuration numerical value as double
@param key The key to configure
@param val The value to set to the key
\note you can get the error message by doing something like get_global_param_string("errstring",output)
MAXIMUM_TABLE_DIRECTORY_SIZE_IN_GB, "MAXIMUM_TABLE_DIRECTORY_SIZE_IN_GB", 1.0, "The maximum allowed size of the directory that is used to store tabular data"
PHASE_ENVELOPE_STARTING_PRESSURE_PA, "PHASE_ENVELOPE_STARTING_PRESSURE_PA", 100.0, "Starting pressure [Pa] for phase envelope construction"
R_U_CODATA, "R_U_CODATA", 8.3144598, "The value for the ideal gas constant in J/mol/K according to CODATA 2014.  This value is used to harmonize all the ideal gas constants. This is especially important in the critical region."
SPINODAL_MINIMUM_DELTA, "SPINODAL_MINIMUM_DELTA", 0.5, "The minimal delta to be used in tracing out the spinodal; make sure that the EOS has a spinodal at this value of delta=rho/rho_r"
"""
function set_config(key::AbstractString, val::Real)
  ccall( (:set_config_double, "CoolProp"), Void, (Ptr{UInt8}, Float64), key, val)
  return get_global_param_string("errstring")
end

"""
    set_config(key::AbstractString, val::Bool)

\brief Set configuration value as a boolean
@param key The key to configure
@param val The value to set to the key
\note you can get the error message by doing something like get_global_param_string("errstring",output)
NORMALIZE_GAS_CONSTANTS, "NORMALIZE_GAS_CONSTANTS", true, "If true, for mixtures, the molar gas constant (R) will be set to the CODATA value"
CRITICAL_WITHIN_1UK, "CRITICAL_WITHIN_1UK", true, "If true, any temperature within 1 uK of the critical temperature will be considered to be AT the critical point"
CRITICAL_SPLINES_ENABLED, "CRITICAL_SPLINES_ENABLED", true, "If true, the critical splines will be used in the near-vicinity of the critical point"
SAVE_RAW_TABLES, "SAVE_RAW_TABLES", false, "If true, the raw, uncompressed tables will also be written to file"
REFPROP_DONT_ESTIMATE_INTERACTION_PARAMETERS, "REFPROP_DONT_ESTIMATE_INTERACTION_PARAMETERS", false, "If true, if the binary interaction parameters in REFPROP are estimated, throw an error rather than silently continuing"
REFPROP_IGNORE_ERROR_ESTIMATED_INTERACTION_PARAMETERS, "REFPROP_IGNORE_ERROR_ESTIMATED_INTERACTION_PARAMETERS", false, "If true, if the binary interaction parameters in REFPROP are unable to be estimated, silently continue rather than failing"
REFPROP_USE_GERG, "REFPROP_USE_GERG", false, "If true, rather than using the highly-accurate pure fluid equations of state, use the pure-fluid EOS from GERG-2008"
REFPROP_USE_PENGROBINSON, "REFPROP_USE_PENGROBINSON", false, "If true, rather than using the highly-accurate pure fluid equations of state, use the Peng-Robinson EOS"
DONT_CHECK_PROPERTY_LIMITS, "DONT_CHECK_PROPERTY_LIMITS", false, "If true, when possible, CoolProp will skip checking whether values are inside the property limits"
HENRYS_LAW_TO_GENERATE_VLE_GUESSES, "HENRYS_LAW_TO_GENERATE_VLE_GUESSES", false, "If true, when doing water-based mixture dewpoint calculations, use Henry's Law to generate guesses for liquid-phase composition"
OVERWRITE_FLUIDS, "OVERWRITE_FLUIDS", false, "If true, and a fluid is added to the fluids library that is already there, rather than not adding the fluid (and probably throwing an exception), overwrite it"
OVERWRITE_DEPARTURE_FUNCTION, "OVERWRITE_DEPARTURE_FUNCTION", false, "If true, and a departure function to be added is already there, rather than not adding the departure function (and probably throwing an exception), overwrite it"
OVERWRITE_BINARY_INTERACTION, "OVERWRITE_BINARY_INTERACTION", false, "If true, and a pair of binary interaction pairs to be added is already there, rather than not adding the binary interaction pair (and probably throwing an exception), overwrite it"
"""
function set_config(key::AbstractString, val::Bool)
  ccall( (:set_config_bool, "CoolProp"), Void, (Ptr{UInt8}, UInt8), key, val)
  return get_global_param_string("errstring")
end

###
#    /**
#     * @brief Set the departure functions in the departure function library from a string format
#     * @param string_data The departure functions to be set, either provided as a JSON-formatted string
#     *                    or as a string of the contents of a HMX.BNC file from REFPROP
#     * @param errcode The errorcode that is returned (0 = no error, !0 = error)
#     * @param message_buffer A buffer for the error code
#     * @param buffer_length The length of the buffer for the error code
#     *
#     * @note By default, if a departure function already exists in the library, this is an error,
#     *       unless the configuration variable OVERWRITE_DEPARTURE_FUNCTIONS is set to true
#     */
#    EXPORT_CODE void CONVENTION set_departure_functions(const char * string_data, long *errcode, char *message_buffer, const long buffer_length);
###

"""
    set_reference_stateS(Ref::AbstractString, reference_state::AbstractString)

\ref CoolProp::set_reference_stateS
@returns error_code 1 = Ok 0 = error
"""
function set_reference_stateS(Ref::AbstractString, reference_state::AbstractString)
  val = ccall( (:set_reference_stateS, "CoolProp"), Cint, (Ptr{UInt8},Ptr{UInt8}), Ref,reference_state)
  if val == 0
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return val
end

###
#    /**
#     * \overload
#     * \sa \ref CoolProp::set_reference_stateD
#     * @returns error_code 1 = Ok 0 = error
#     */
#    EXPORT_CODE int CONVENTION set_reference_stateD(const char *Ref, double T, double rhomolar, double hmolar0, double smolar0);
#    /** \brief FORTRAN 77 style wrapper of the PropsSI function
#     * \overload
#     * \sa \ref CoolProp::PropsSI(const std::string &, const std::string &, double, const std::string &, double, const std::string&)
#     *
#     * \note If there is an error, a huge value will be returned, you can get the error message by doing something like get_global_param_string("errstring",output)
#     */
#    EXPORT_CODE void CONVENTION propssi_(const char *Output, const char *Name1, const double *Prop1, const char *Name2, const double *Prop2, const char * Ref, double *output);
###

"""
    F2K(TF::Real)

Convert from degrees Fahrenheit to Kelvin (useful primarily for testing).
"""
function F2K(TF::Real)
  return ccall( (:F2K, "CoolProp"), Cdouble, (Cdouble,), TF)
end

"""
    K2F(TK::Real)

Convert from Kelvin to degrees Fahrenheit (useful primarily for testing).
"""
function K2F(TK::Real)
  return ccall( (:K2F, "CoolProp"), Cdouble, (Cdouble,), TK)
end

"""
    get_param_index(param::AbstractString)

Get the index for a parameter "T", "P", etc.

@returns index The index as a long.  If input is invalid, returns -1
"""
function get_param_index(param::AbstractString)
  val = ccall( (:get_param_index, "CoolProp"), Clong, (Ptr{UInt8},), param)
  if val == -1
    error("CoolProp: Unknown parameter: ", param)
  end
  return val
end

"""
    get_input_pair_index(param::AbstractString)

Get the index for an input pair for AbstractState.update function.

@returns index The index as a long.  If input is invalid, returns -1
"""
function get_input_pair_index(param::AbstractString)
  val = ccall( (:get_input_pair_index, "CoolProp"), Clong, (Ptr{UInt8},), param)
  if val == -1
    error("CoolProp: Unknown input pair: ", param)
  end
  return val
end

# ---------------------------------
#        Getter and setter for debug level
# ---------------------------------

"""
    get_debug_level()

Get the debug level.

@returns level The level of the verbosity for the debugging output (0-10) 0: no debgging output
"""
function get_debug_level()
  ccall( (:get_debug_level, "CoolProp"), Cint, () )
end

"""
    set_debug_level(level::Int)

Set the debug level.

@param level The level of the verbosity for the debugging output (0-10) 0: no debgging output
"""
function set_debug_level(level::Int)
  ccall( (:set_debug_level, "CoolProp"), Void, (Cint,), level)
end

###
#    /* \brief Extract a value from the saturation ancillary
#     *
#     * @param fluid_name The name of the fluid to be used - HelmholtzEOS backend only
#     * @param output The desired output variable ("P" for instance for pressure)
#     * @param Q The quality, 0 or 1
#     * @param input The input variable ("T")
#     * @param value The input value
#     */
#    EXPORT_CODE double CONVENTION saturation_ancillary(const char *fluid_name, const char *output, int Q, const char *input, double value);
###

# ---------------------------------
#        Humid Air Properties
# ---------------------------------

"""
    HAPropsSI(Output::AbstractString, Name1::AbstractString, Value1::Real, Name2::AbstractString, Value2::Real, Name3::AbstractString, Value3::Real)

DLL wrapper of the HAPropsSI function.

\ref HumidAir::HAPropsSI(const char *OutputName, const char *Input1Name, double Input1, const char *Input2Name, double Input2, const char *Input3Name, double Input3);
\note If there is an error, a huge value will be returned, you can get the error message by doing something like get_global_param_string("errstring",output)
"""
function HAPropsSI(Output::AbstractString, Name1::AbstractString, Value1::Real, Name2::AbstractString, Value2::Real, Name3::AbstractString, Value3::Real)
  val = ccall( (:HAPropsSI, "CoolProp"), Cdouble, (Ptr{UInt8},Ptr{UInt8},Float64,Ptr{UInt8},Float64,Ptr{UInt8},Float64), Output,Name1,Value1,Name2,Value2,Name3,Value3)
  if val == Inf
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return val
end

###
#    /** \brief DLL wrapper of the cair_sat function
#     * \sa \ref HumidAir::cair_sat(double);
#     */
#    EXPORT_CODE double CONVENTION cair_sat(double T);
###

# ---------------------------------
#        Low-level access
# ---------------------------------

"""
    AbstractState_factory(backend::AbstractString, fluids::AbstractString)

Generate an AbstractState instance, return an integer handle to the state class generated to be used in the other low-level accessor functions.

param backend The backend you will use, "HEOS", "REFPROP", etc.
param fluids '&' delimited list of fluids
return A handle to the state class generated
"""
function AbstractState_factory(backend::AbstractString, fluids::AbstractString)
  AbstractState = ccall( (:AbstractState_factory, "CoolProp"), Clong, (Ptr{UInt8},Ptr{UInt8},Ref{Clong},Ptr{UInt8},Clong), backend,fluids,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return AbstractState
end

"""
    AbstractState_free(handle::Clong)

Release a state class generated by the low-level interface wrapper.

param handle The integer handle for the state class stored in memory
"""
function AbstractState_free(handle::Clong)
  ccall( (:AbstractState_free, "CoolProp"), Void, (Clong,Ref{Clong},Ptr{UInt8},Clong), handle,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

"""
    AbstractState_set_fractions(handle::Clong,fractions::Array)

Set the fractions (mole, mass, volume) for the AbstractState.

param handle The integer handle for the state class stored in memory
param fractions The array of fractions
"""
function AbstractState_set_fractions(handle::Clong,fractions::Array)
  ccall( (:AbstractState_set_fractions, "CoolProp"), Void, (Clong,Ptr{Cdouble},Clong,Ref{Clong},Ptr{UInt8},Clong), handle,fractions,length(fractions),errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

"""
    AbstractState_update(handle::Clong,input_pair::Clong,value1::Real,value2::Real)
    AbstractState_update(handle::Clong,input_pair::AbstractString,value1::Real,value2::Real)

Update the state of the AbstractState.

param handle The integer handle for the state class stored in memory
param input_pair The integer value for the input pair obtained from get_input_pair_index(param::AbstractString)
param value1 The first input value
param value2 The second input value
"""
function AbstractState_update(handle::Clong,input_pair::Clong,value1::Real,value2::Real)
  ccall( (:AbstractState_update, "CoolProp"), Void, (Clong,Clong,Cdouble,Cdouble,Ref{Clong},Ptr{UInt8},Clong), handle,input_pair,value1,value2,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

function AbstractState_update(handle::Clong,input_pair::AbstractString,value1::Real,value2::Real)
  AbstractState_update(handle::Clong,get_input_pair_index(input_pair),value1::Real,value2::Real)
  return nothing
end

"""
    AbstractState_specify_phase(handle::Clong,phase::AbstractString)

Specify the phase to be used for all further calculations.

handle The integer handle for the state class stored in memory
phase The string with the phase to use
errcode The errorcode that is returned (0 = no error, !0 = error)
message_buffer A buffer for the error code
buffer_length The length of the buffer for the error code
"""
function AbstractState_specify_phase(handle::Clong,phase::AbstractString)
  ccall( (:AbstractState_specify_phase, "CoolProp"), Void, (Clong,Ptr{UInt8},Ref{Clong},Ptr{UInt8},Clong), handle,phase,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

"""
    bstractState_unspecify_phase(handle::Clong)

Unspecify the phase to be used for all further calculations.

handle The integer handle for the state class stored in memory
errcode The errorcode that is returned (0 = no error, !0 = error)
message_buffer A buffer for the error code
buffer_length The length of the buffer for the error code
"""
function AbstractState_unspecify_phase(handle::Clong)
  ccall( (:AbstractState_unspecify_phase, "CoolProp"), Void, (Clong,Ref{Clong},Ptr{UInt8},Clong), handle,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

"""
    AbstractState_keyed_output(handle::Clong, param::Clong)
    AbstractState_output(handle::Clong, param::AbstractString)

Get an output value from the AbstractState using an integer value for the desired output value.

param handle The integer handle for the state class stored in memory
param param The integer value for the parameter you want
"""
function AbstractState_keyed_output(handle::Clong, param::Clong)
  output = ccall( (:AbstractState_keyed_output, "CoolProp"), Cdouble, (Clong,Clong,Ref{Clong},Ptr{UInt8},Clong), handle,param,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  elseif output == -Inf
    error("CoolProp: no correct state has been set with AbstractState_update")
  end
  return output
end
function AbstractState_output(handle::Clong, param::AbstractString)
  return AbstractState_keyed_output(handle, get_param_index(param))
end

#    /**
#    * @brief Calculate a saturation derivative from the AbstractState using integer values for the desired parameters
#    * @param handle The integer handle for the state class stored in memory
#    * @param Of The parameter of which the derivative is being taken
#    * @param Wrt The derivative with with respect to this parameter
#    * @param errcode The errorcode that is returned (0 = no error, !0 = error)
#    * @param message_buffer A buffer for the error code
#    * @param buffer_length The length of the buffer for the error code
#    * @return
#    */
#    EXPORT_CODE double CONVENTION AbstractState_first_saturation_deriv(const long handle, const long Of, const long Wrt, long *errcode, char *message_buffer, const long buffer_length);
#
#    /**
#    * @brief Calculate the first partial derivative in homogeneous phases from the AbstractState using integer values for the desired parameters
#    * @param handle The integer handle for the state class stored in memory
#    * @param Of The parameter of which the derivative is being taken
#    * @param Wrt The derivative with with respect to this parameter
#    * @param Constant The parameter that is not affected by the derivative
#    * @param errcode The errorcode that is returned (0 = no error, !0 = error)
#    * @param message_buffer A buffer for the error code
#    * @param buffer_length The length of the buffer for the error code
#    * @return
#    */
#    EXPORT_CODE double CONVENTION AbstractState_first_partial_deriv(const long handle, const long Of, const long Wrt, const long Constant, long *errcode, char *message_buffer, const long buffer_length);

"""
    AbstractState_update_and_common_out{R1<:Real,R2<:Real,F<:AbstractFloat}(handle::Clong, input_pair::Clong, value1::Array{R1}, value2::Array{R2}, length::Real, T::Array{F}, p::Array{F}, rhomolar::Array{F}, hmolar::Array{F}, smolar::Array{F})
    AbstractState_update_and_common_out{R1<:Real,R2<:Real,F<:AbstractFloat}(handle::Clong, input_pair::AbstractString, value1::Array{R1}, value2::Array{R2}, length::Real, T::Array{F}, p::Array{F}, rhomolar::Array{F}, hmolar::Array{F}, smolar::Array{F})

Update the state of the AbstractState and get an output value five common outputs (temperature, pressure, molar density, molar enthalpy and molar entropy) from the AbstractState using pointers as inputs and output to allow array computation.

handle The integer handle for the state class stored in memory
input_pair The integer value for the input pair obtained from get_input_pair_index
value1 The pointer to the array of the first input parameters
value2 The pointer to the array of the second input parameters
length The number of elements stored in the arrays (both inputs and outputs MUST be the same length)
T The pointer to the array of temperature
p The pointer to the array of pressure
rhomolar The pointer to the array of molar density
hmolar The pointer to the array of molar enthalpy
smolar The pointer to the array of molar entropy
"""
function AbstractState_update_and_common_out{R1<:Real,R2<:Real,F<:AbstractFloat}(handle::Clong, input_pair::Clong, value1::Array{R1}, value2::Array{R2}, length::Real, T::Array{F}, p::Array{F}, rhomolar::Array{F}, hmolar::Array{F}, smolar::Array{F})
  ccall( (:AbstractState_update_and_common_out, "CoolProp"), Void, (Clong,Clong,Ref{Cdouble},Ref{Cdouble},Clong,Ref{Cdouble},Ref{Cdouble},Ref{Cdouble},Ref{Cdouble},Ref{Cdouble},Ref{Clong},Ptr{UInt8},Clong), handle,input_pair,value1,value2,length,T,p,rhomolar,hmolar,smolar,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

function AbstractState_update_and_common_out{R1<:Real,R2<:Real,F<:AbstractFloat}(handle::Clong, input_pair::AbstractString, value1::Array{R1}, value2::Array{R2}, length::Real, T::Array{F}, p::Array{F}, rhomolar::Array{F}, hmolar::Array{F}, smolar::Array{F})
  AbstractState_update_and_common_out(handle, get_input_pair_index(input_pair), value1, value2, length, T, p, rhomolar, hmolar, smolar)
  return nothing
end

"""
    AbstractState_update_and_1_out{R1<:Real,R2<:Real,F<:AbstractFloat}(handle::Clong, input_pair::Clong, value1::Array{R1}, value2::Array{R2}, length::Real, output::Clong, out::Array{F})

Update the state of the AbstractState and get one output value (temperature, pressure, molar density, molar enthalpy and molar entropy) from the AbstractState using pointers as inputs and output to allow array computation.

handle The integer handle for the state class stored in memory
input_pair The integer value for the input pair obtained from get_input_pair_index
value1 The pointer to the array of the first input parameters
value2 The pointer to the array of the second input parameters
length The number of elements stored in the arrays (both inputs and outputs MUST be the same length)
output The indice for the output desired
out The pointer to the array for output
"""
function AbstractState_update_and_1_out{R1<:Real,R2<:Real,F<:AbstractFloat}(handle::Clong, input_pair::Clong, value1::Array{R1}, value2::Array{R2}, length::Real, output::Clong, out::Array{F})
  ccall( (:AbstractState_update_and_1_out, "CoolProp"), Void, (Clong,Clong,Ref{Cdouble},Ref{Cdouble},Clong,Clong,Ref{Cdouble},Ref{Clong},Ptr{UInt8},Clong), handle,input_pair,value1,value2,length,output,out,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end
function AbstractState_update_and_1_out{R1<:Real,R2<:Real,F<:AbstractFloat}(handle::Clong, input_pair::AbstractString, value1::Array{R1}, value2::Array{R2}, length::Real, output::AbstractString, out::Array{F})
  AbstractState_update_and_1_out(handle, get_input_pair_index(input_pair), value1, value2, length, get_param_index(output), out)
  return nothing
end

"""
    AbstractState_update_and_5_out{R1<:Real,R2<:Real,F<:AbstractFloat}(handle::Clong, input_pair::Clong, value1::Array{R1}, value2::Array{R2}, length::Real, outputs::Array{Clong}, out1::Array{F}, out2::Array{F}, out3::Array{F}, out4::Array{F}, out5::Array{F})
    AbstractState_update_and_5_out{R1<:Real,R2<:Real,S<:AbstractString,F<:AbstractFloat}(handle::Clong, input_pair::AbstractString, value1::Array{R1}, value2::Array{R2}, length::Real, outputs::Array{S}, out1::Array{F}, out2::Array{F}, out3::Array{F}, out4::Array{F}, out5::Array{F})

Update the state of the AbstractState and get an output value five common outputs (temperature, pressure, molar density, molar enthalpy and molar entropy) from the AbstractState using pointers as inputs and output to allow array computation.

handle The integer handle for the state class stored in memory
input_pair The integer value for the input pair obtained from get_input_pair_index
value1 The pointer to the array of the first input parameters
value2 The pointer to the array of the second input parameters
length The number of elements stored in the arrays (both inputs and outputs MUST be the same length)
outputs The 5-element vector of indices for the outputs desired
out1 The pointer to the array for the first output
out2 The pointer to the array for the second output
out3 The pointer to the array for the third output
out4 The pointer to the array for the fourth output
out5 The pointer to the array for the fifth output
"""
function AbstractState_update_and_5_out{R1<:Real,R2<:Real,F<:AbstractFloat}(handle::Clong, input_pair::Clong, value1::Array{R1}, value2::Array{R2}, length::Real, outputs::Array{Clong}, out1::Array{F}, out2::Array{F}, out3::Array{F}, out4::Array{F}, out5::Array{F})
  ccall( (:AbstractState_update_and_5_out, "CoolProp"), Void, (Clong,Clong,Ref{Cdouble},Ref{Cdouble},Clong,Ref{Clong},Ref{Cdouble},Ref{Cdouble},Ref{Cdouble},Ref{Cdouble},Ref{Cdouble},Ref{Clong},Ptr{UInt8},Clong), handle,input_pair,value1,value2,length,outputs,out1,out2,out3,out4,out5,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

function AbstractState_update_and_5_out{R1<:Real,R2<:Real,S<:AbstractString,F<:AbstractFloat}(handle::Clong, input_pair::AbstractString, value1::Array{R1}, value2::Array{R2}, length::Real, outputs::Array{S}, out1::Array{F}, out2::Array{F}, out3::Array{F}, out4::Array{F}, out5::Array{F})
  outputs_key = Array(Clong,5)
  for k = 1:5
    outputs_key[k] = get_param_index(outputs[k])
  end
  AbstractState_update_and_5_out(handle, get_input_pair_index(input_pair), value1, value2, length, outputs_key, out1, out2, out3, out4, out5)
  return nothing
end

"""
    AbstractState_set_binary_interaction_double(handle::Clong,i::Int, j::Int, parameter::AbstractString, value::Cdouble)

Set binary interraction parrameter for mixtures.

handle The integer handle for the state class stored in memory
i indice of the first fluid of the binary pair
j indice of the second fluid of the binary pair
parameter string wit the name of the parameter
value the value of the binary interaction parameter
"""
function AbstractState_set_binary_interaction_double(handle::Clong,i::Int, j::Int, parameter::AbstractString, value::Cdouble)
  ccall( (:AbstractState_set_binary_interaction_double, "CoolProp"), Void, (Clong,Clong,Clong,Ptr{UInt8},Cdouble,Ref{Clong},Ptr{UInt8},Clong), handle,i,j,parameter,value,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

"""
    AbstractState_set_cubic_alpha_C(handle::Clong, i::Int, parameter::AbstractString, c1::Cdouble, c2::Cdouble, c3::Cdouble)

 Set cubic's alpha function parameters.

handle The integer handle for the state class stored in memory
i indice of the fluid the parramter should be applied too (for mixtures)
parameter the string specifying the alpha function to use, ex "TWU" for the TWU alpha function
c1 the first parameter for the alpha function
c2 the second parameter for the alpha function
c3 the third parameter for the alpha function
"""
function AbstractState_set_cubic_alpha_C(handle::Clong, i::Int, parameter::AbstractString, c1::Cdouble, c2::Cdouble, c3::Cdouble)
  ccall( (:AbstractState_set_cubic_alpha_C, "CoolProp"), Void, (Clong,Clong,Ptr{UInt8},Cdouble,Cdouble,Cdouble,Ref{Clong},Ptr{UInt8},Clong), handle,i,parameter,c1,c2,c3,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

"""
    AbstractState_set_fluid_parameter_double(handle::Clong, i::Int, parameter::AbstractString, value::Cdouble)

Set some fluid parameter (ie volume translation for cubic).

handle The integer handle for the state class stored in memory
i indice of the fluid the parramter should be applied too (for mixtures)
parameter string wit the name of the parameter
value the value of the parameter
"""
function AbstractState_set_fluid_parameter_double(handle::Clong, i::Int, parameter::AbstractString, value::Cdouble)
  ccall( (:AbstractState_set_fluid_parameter_double, "CoolProp"), Void, (Clong,Clong,Ptr{UInt8},Cdouble,Ref{Clong},Ptr{UInt8},Clong), handle,i,parameter,value,errcode,message_buffer::Array{UInt8,1},buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

#    /**
#     * @brief Build the phase envelope
#     * @param handle The integer handle for the state class stored in memory
#     * @param level How much refining of the phase envelope ("none" to skip refining (recommended))
#     * @param errcode The errorcode that is returned (0 = no error, !0 = error)
#     * @param message_buffer A buffer for the error code
#     * @param buffer_length The length of the buffer for the error code
#     * @return
#     *
#     * @note If there is an error in an update call for one of the inputs, no change in the output array will be made
#     */
#    EXPORT_CODE void CONVENTION AbstractState_build_phase_envelope(const long handle, const char *level, long *errcode, char *message_buffer, const long buffer_length);
#
#    /**
#     * @brief Get data from the phase envelope for the given mixture composition
#     * @param handle The integer handle for the state class stored in memory
#     * @param length The number of elements stored in the arrays (both inputs and outputs MUST be the same length)
#     * @param T The pointer to the array of temperature (K)
#     * @param p The pointer to the array of pressure (Pa)
#     * @param rhomolar_vap The pointer to the array of molar density for vapor phase (m^3/mol)
#     * @param rhomolar_liq The pointer to the array of molar density for liquid phase (m^3/mol)
#     * @param x The compositions of the "liquid" phase (WARNING: buffer should be Ncomp*Npoints in length, at a minimum, but there is no way to check buffer length at runtime)
#     * @param y The compositions of the "vapor" phase (WARNING: buffer should be Ncomp*Npoints in length, at a minimum, but there is no way to check buffer length at runtime)
#     * @param errcode The errorcode that is returned (0 = no error, !0 = error)
#     * @param message_buffer A buffer for the error code
#     * @param buffer_length The length of the buffer for the error code
#     * @return
#     *
#     * @note If there is an error in an update call for one of the inputs, no change in the output array will be made
#     */
#    EXPORT_CODE void CONVENTION AbstractState_get_phase_envelope_data(const long handle, const long length, double* T, double* p, double* rhomolar_vap, double *rhomolar_liq, double *x, double *y, long *errcode, char *message_buffer, const long buffer_length);
#
#    /**
#     * @brief Build the spinodal
#     * @param handle The integer handle for the state class stored in memory
#     * @param errcode The errorcode that is returned (0 = no error, !0 = error)
#     * @param message_buffer A buffer for the error code
#     * @param buffer_length The length of the buffer for the error code
#     * @return
#     */
#    EXPORT_CODE void CONVENTION AbstractState_build_spinodal(const long handle, long *errcode, char *message_buffer, const long buffer_length);
#
#    /**
#     * @brief Get data for the spinodal curve
#     * @param handle The integer handle for the state class stored in memory
#     * @param length The number of elements stored in the arrays (all outputs MUST be the same length)
#     * @param tau The pointer to the array of reciprocal reduced temperature
#     * @param delta The pointer to the array of reduced density
#     * @param M1 The pointer to the array of M1 values (when L1=M1=0, critical point)
#     * @param errcode The errorcode that is returned (0 = no error, !0 = error)
#     * @param message_buffer A buffer for the error code
#     * @param buffer_length The length of the buffer for the error code
#     * @return
#     *
#     * @note If there is an error, no change in the output arrays will be made
#     */
#    EXPORT_CODE void CONVENTION AbstractState_get_spinodal_data(const long handle, const long length, double* tau, double* delta, double* M1, long *errcode, char *message_buffer, const long buffer_length);
#
#    /**
#     * @brief Calculate all the critical points for a given composition
#     * @param handle The integer handle for the state class stored in memory
#     * @param length The length of the buffers passed to this function
#     * @param T The pointer to the array of temperature (K)
#     * @param p The pointer to the array of pressure (Pa)
#     * @param rhomolar The pointer to the array of molar density (m^3/mol)
#     * @param stable The pointer to the array of boolean flags for whether the critical point is stable (1) or unstable (0)
#     * @param errcode The errorcode that is returned (0 = no error, !0 = error)
#     * @param message_buffer A buffer for the error code
#     * @param buffer_length The length of the buffer for the error code
#     * @return
#     *
#     * @note If there is an error in an update call for one of the inputs, no change in the output array will be made
#     */
#    EXPORT_CODE void CONVENTION AbstractState_all_critical_points(const long handle, const long length, double *T, double *p, double *rhomolar, long *stable, long *errcode, char *message_buffer, const long buffer_length);

end #module