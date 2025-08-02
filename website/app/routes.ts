import { type RouteConfig, index, route } from "@react-router/dev/routes";

export default [
  route("/", "routes/home.tsx"),
  route("/benchmarks/calendar", "routes/benchmarks.calendar.tsx"),
  route("/benchmarks/parking-garage", "routes/benchmarks.parking-garage.tsx"),
  route("/benchmarks/school-library", "routes/benchmarks.school-library.tsx"),
  route("/benchmarks/vending-machine", "routes/benchmarks.vending-machine.tsx"),
] satisfies RouteConfig;

