# taller-02/R/abreviaturas.R
#
# Nombres cortos para las 57 variables de EIA.csv, que llegan a
# tener 60 caracteres y no caben en los gráficos. Se carga desde el
# chunk de configuración y su código se muestra en el Apéndice B.

# Cambia cada fragmento del nombre original por su abreviatura y
# quita la unidad del final (TBPD, BKWH, MK, MMTCD o BB). El orden
# importa: Los fragmentos largos van antes que los cortos que
# contienen.
abreviar <- function(v) {
  reglas <- c(
    Crude_oil_including_lease_condensate = "Crudo",
    Petroleum_and_other_liquids = "PetLiq",
    Refined_petroleum_products = "Refinados",
    Liquefied_petroleum_gases_.LPG. = "GLP",
    Natural_gas_plant_liquids = "LGN",
    Bunker_residual_fuel_oil = "BunkerRes",
    Bunker_fuel = "Bunker",
    Distillate_fuel_oil = "Destilado",
    Residual_fuel_oil = "Residual",
    Motor_gasoline = "Gasolina",
    Jet_fuel = "Jet",
    Kerosene = "Queroseno",
    Other_liquids = "OtrosLiq",
    Other_refined_products = "OtrosRef",
    Refinery_processing_gain = "GananciaRef",
    Hydroelectric_pumped_storage_electricity = "Bombeo",
    Hydroelectricity = "Hidro",
    Biomass_and_waste_electricity = "Biomasa",
    Fossil_fuels_electricity = "Fosil",
    Geothermal_electricity = "Geotermica",
    Non.hydro_renewable_electricity = "NoHidro",
    Renewable_electricity = "Renov",
    Nuclear_electricity = "Nuclear",
    Solar_electricity = "Solar",
    Tide_and_wave_electricity = "Mareas",
    Wind_electricity = "Eolica",
    Electricity = "Elec",
    installed_capacity = "cap",
    net_generation = "gen",
    net_consumption = "cons",
    net_imports = "impNeta",
    distribution_losses = "perdidas",
    CO2_emissions = "CO2",
    consumption = "cons",
    production = "prod",
    exports = "exp",
    imports = "imp",
    reserves = "reservas")
  for (r in names(reglas))
    v <- gsub(r, reglas[[r]], v, fixed = TRUE)
  sub("_(TBPD|BKWH|MK|MMTCD|BB)$", "", v)
}

# Las columnas numéricas, con el país como nombre de fila y los
# nombres abreviados.
numericas <- function(d) {
  num <- d[vapply(d, is.numeric, logical(1))]
  rownames(num) <- d$Country
  names(num) <- abreviar(names(num))
  num
}
