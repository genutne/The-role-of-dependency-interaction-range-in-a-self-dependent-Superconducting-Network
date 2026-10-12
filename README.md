# Microscopic Mechanisms of Thermally Coupled Superconducting Networks

This repository contains the MATLAB simulation code associated with the research article:

**"The role of dependency range in thermally coupled superconducting networks"**  
Nahala Yadid, Bnaya Gross, Shlomo Havlin, and Nadav Shnerb.

**Publication:** [Link to be added]

## Overview

The code simulates the dynamics of superconducting networks with heat-mediated dependency interactions, using a Resistively Shunted Josephson Junction (RSJJ) model.

The simulations combine electrical current redistribution, Joule heating, thermal diffusion, and temperature-dependent superconducting transitions. They allow us to investigate how the thermal interaction range affects network stability, resistance transitions, and cascading dynamics.

In particular, the simulations capture continuous, nucleation-driven, and mixed-order phase transitions, including the characteristic plateau associated with critical branching dynamics and the propagation of superconducting fronts.

The repository supports both a single self-dependent superconducting network and two thermally coupled superconducting networks.

## Main Simulation Files

- **`one_SC_network_main.m`** — Main script for simulating a single superconducting network with self-mediated thermal interactions.
- **`interdependent_SC_networks_main.m`** — Main script for simulating two superconducting networks coupled through heat transfer.

The simulations can be performed at different temperatures, applied currents, and thermal diffusion parameters. The evolution of the network resistance is tracked through successive iterations until a steady state is reached.

## Requirements

The code is written in MATLAB. GNU Octave may also be used as an open-source alternative, although full compatibility has not been verified.

## Simulation Procedure

The simulation iteratively solves the coupled electrical and thermal dynamics of the superconducting network.

**Initialization**

Define the network geometry, physical parameters, and initial states of the superconducting segments.

**Parameter Sweep**

Vary an external control parameter, such as temperature (`dT`) or applied current (`dI`), in small increments. At each increment, the network evolves iteratively toward a steady state through the following steps:

1. **`Voltage_nodes`** — Constructs the conductance matrix from the network structure and resistor states, and solves Kirchhoff's equations to determine the voltage at each node.

2. **Convergence check** — Evaluates whether the system has reached a steady state.

3. **`find_currents`** — Calculates the current flowing through each resistor using the node voltages and Kirchhoff's laws, and determines the corresponding Joule heating.

4. **`heat_transfer_spectral`** — Computes the spatial redistribution of dissipated heat by solving the heat diffusion equation using a spectral method.

5. **`update_resistors_SC`** — Updates the resistance and superconducting state of each segment according to its local temperature, current, and Josephson current–voltage characteristics.

These steps are repeated until convergence is achieved.

**Resistance Measurement**

After convergence, the total network resistance is calculated. The external parameter is then incremented, and the procedure is repeated to construct the resistance–temperature or resistance–current curves.

The iterative dynamics can also be analyzed to investigate cascading transitions, nucleation processes, and the plateau preceding abrupt resistance changes.

## Reference

If you use this code in your research, please cite:

N. Yadid, B. Gross, S. Havlin, and N. Shnerb, "The role of dependency range in thermally coupled superconducting networks."

[Publication details and DOI to be added]
