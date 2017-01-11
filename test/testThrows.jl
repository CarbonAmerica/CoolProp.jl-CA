instr = "invalid value"
inhandle = 999%Clong
@test_throws ErrorException set_reference_stateS("Water", instr);
@test_throws ErrorException HAPropsSI(instr, "T", 298.15, "P", 101325, "R", 0.5)
@test_throws ErrorException HAPropsSI("H", instr, 298.15, "P", 101325, "R", 0.5)
@test_throws ErrorException PropsSI(instr, "rhomolar_critical")
@test_throws ErrorException PropsSI("n-Butane", instr)
@test_throws ErrorException PropsSI(instr, "T", 300, "P", 101325, "n-Butane")
@test_throws ErrorException PropsSI("D", "T", 300, "P", 101325, instr)
@test_throws ErrorException PhaseSI(instr, 300, "Q", 1, "Water")
@test_throws ErrorException PhaseSI("T", 300, "Q", 1, instr)
@test_throws ErrorException set_reference_stateS(instr, "DEF")
@test_throws ErrorException set_reference_stateS("Water", instr)
@test_throws ErrorException get_global_param_string(instr)
@test_throws ErrorException get_parameter_information_string(instr)
@test_throws ErrorException get_parameter_information_string("HMOLAR", instr)
@test_throws ErrorException get_fluid_param_string(instr, "aliases")
@test_throws ErrorException get_fluid_param_string("Water", instr)
@test_throws ErrorException get_param_index(instr)
@test_throws ErrorException get_input_pair_index(instr)
@test_throws ErrorException AbstractState_factory(instr, "R245fa")
@test_throws ErrorException AbstractState_factory("HEOS", instr)
@test_throws ErrorException AbstractState_free(inhandle)
@test_throws ErrorException AbstractState_set_fractions(inhandle, [0.0])
@test_throws ErrorException AbstractState_update(inhandle, "PQ_INPUTS", 101325, 0)
handle = AbstractState_factory("HEOS", "Water&Ethanol")
@test_throws ErrorException AbstractState_update(handle, instr, 101325, 0)
@test_throws ErrorException AbstractState_update(handle, inhandle, 101325, 0)
@test_throws ErrorException AbstractState_output(handle, instr)
@test_throws ErrorException AbstractState_output(inhandle, "T")
@test_throws ErrorException AbstractState_keyed_output(inhandle, 1%Clong)
@test_throws ErrorException AbstractState_keyed_output(handle, inhandle)
@test_throws ErrorException AbstractState_specify_phase(inhandle, "phase_gas")
@test_throws ErrorException AbstractState_specify_phase(handle, instr)
@test_throws ErrorException AbstractState_unspecify_phase(inhandle)
pq_inputs = get_input_pair_index("PQ_INPUTS")
temp = [0.0]; p = [0.0]; rhomolar = [0.0]; hmolar = [0.0]; smolar = [0.0]
@test_throws ErrorException AbstractState_update_and_common_out(inhandle, pq_inputs, [101325.0], [0.0], 1, temp, p, rhomolar, hmolar, smolar)
@test_throws ErrorException AbstractState_update_and_common_out(handle, instr, [101325.0], [0.0], 1, temp, p, rhomolar, hmolar, smolar)
out = [0.0]
@test_throws ErrorException AbstractState_update_and_1_out(inhandle, pq_inputs, [101325.0], [0.0], 1, 1%Clong, out)
@test_throws ErrorException AbstractState_update_and_1_out(handle, instr, [101325.0], [0.0], 1, "T", out)
@test_throws ErrorException AbstractState_update_and_5_out(inhandle, pq_inputs, [101325.0], [0.0], 1, [1%Clong, 1%Clong, 1%Clong, 1%Clong, 1%Clong], out, out, out, out, out)
@test_throws ErrorException AbstractState_update_and_5_out(handle, instr, [101325.0], [0.0], 1, ["T", "T", "T", "T", "T"], out, out, out, out, out)
@test_throws ErrorException AbstractState_set_binary_interaction_double(inhandle, 0, 1, "betaT", 0.987)
@test_throws ErrorException AbstractState_set_binary_interaction_double(handle, 0, 1, instr, 0.987)
AbstractState_free(handle)
handle = AbstractState_factory("SRK", "Ethanol");
@test_throws ErrorException AbstractState_set_fluid_parameter_double(inhandle, 1, "c", 0.0)
@test_throws ErrorException AbstractState_set_fluid_parameter_double(handle, 0, instr, 0.0)
if (branchname == "nightly")
  @test_throws ErrorException AbstractState_set_cubic_alpha_C(inhandle, 0, "TWU", 0.0, 0.0, 0.0)
  @test_throws ErrorException AbstractState_set_cubic_alpha_C(handle, 0, instr, 0.0, 0.0, 0.0)
end
if (haskey(ENV, "testCoolProp") && ENV["testCoolProp"]=="on")
  @test_throws ErrorException saturation_ancillary(instr, "I", 1, "T", 300.0)
  @test_throws ErrorException saturation_ancillary("R410A", instr, 1, "T", 300.0)
  AbstractState_free(handle)
  handle = AbstractState_factory("HEOS", "Water")
  AbstractState_update(handle, "PQ_INPUTS", 15e5, 0)
  @test_throws ErrorException AbstractState_first_saturation_deriv(inhandle, 1%Clong, 2%Clong)
  @test_throws ErrorException AbstractState_first_saturation_deriv(handle, inhandle, 2%Clong)
  @test_throws ErrorException AbstractState_first_partial_deriv(inhandle, 1%Clong, 2%Clong, 3%Clong)
  @test_throws ErrorException AbstractState_first_partial_deriv(handle, inhandle, 2%Clong, 3%Clong)
  @test_throws ErrorException AbstractState_build_phase_envelope(inhandle, "none")
  len=100;t=zeros(len);p=zeros(len);x=zeros(2*len);y=zeros(2*len);rhomolar_vap=zeros(len);rhomolar_liq=zeros(len);
  @test_throws ErrorException AbstractState_get_phase_envelope_data(inhandle, len, t, p, rhomolar_vap, rhomolar_liq, x, y)
  @test_throws ErrorException AbstractState_build_spinodal(inhandle)
  rhomolar=zeros(len); stable=zeros(Clong, len)
  @test_throws ErrorException AbstractState_all_critical_points(inhandle, 2, t, p, rhomolar, stable)
  tau=zeros(len);delta=zeros(len);m1=zeros(len)
  @test_throws ErrorException AbstractState_get_spinodal_data(inhandle, len, tau, delta, m1)
  AbstractState_free(handle)
end
