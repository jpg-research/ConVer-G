package fr.cnrs.liris.jpugetgil.converg.sql;

import com.google.common.collect.Streams;
import fr.cnrs.liris.jpugetgil.converg.sparql.SPARQLOccurrence;
import fr.cnrs.liris.jpugetgil.converg.sparql.SPARQLPositionType;
import fr.cnrs.liris.jpugetgil.converg.sql.operator.FlattenSQLOperator;
import fr.cnrs.liris.jpugetgil.converg.sql.operator.IdentifySQLOperator;
import org.apache.jena.graph.Node;
import org.apache.jena.sparql.algebra.op.OpSlice;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

public class SQLQuery {

    private String sql;

    private SQLContext context;

    private OpSlice opSlice;

    private final String FINALIZE_TABLE_NAME = "indexes_table";

    public SQLQuery(String sql, SQLContext context) {
        this.sql = sql;
        this.context = context;
    }

    public String getSql() {
        return sql;
    }

    public void setSql(String sql) {
        this.sql = sql;
    }

    public void setOpSlice(OpSlice opSlice) {
        this.opSlice = opSlice;
    }

    public SQLContext getContext() {
        return context;
    }

    public void setContext(SQLContext context) {
        this.context = context;
    }

    public SQLQuery finalizeQuery() {
        flattenAndIdentifyAllVariables();
        String select = getSelect();
        String from = getFrom();
        String join = getJoin();

        this.sql = select + from + join;

        if (this.opSlice != null) {
            insertLimit();
        }

        return new SQLQuery(
                this.sql,
                this.context
        );
    }

    private String getSelect() {
        return "SELECT " + Streams.mapWithIndex(this.context.sparqlVarOccurrences().keySet().stream(), (node, index) -> {
            SPARQLOccurrence maxSPARQLOccurrence = SQLUtils.getMaxSPARQLOccurrence(
                    this.context.sparqlVarOccurrences().get(node)
            );

            SQLVariable maxSQLVariable = maxSPARQLOccurrence.getSqlVariable();
            if (maxSPARQLOccurrence.getType() == SPARQLPositionType.AGGREGATED) {
                maxSQLVariable.setSqlVarName(maxSQLVariable.getSqlVarName().replace(".", "agg"));
                return (
                        maxSQLVariable.getSelect() + " as name$" +
                                maxSQLVariable.getSelect()
                );
            } else {
                return (
                        "rl" + index + ".name as name$" + maxSQLVariable.getSqlVarName() +
                                ", rl" + index + ".type as type$" + maxSQLVariable.getSqlVarName()
                );
            }
        }).collect(Collectors.joining(", "));
    }

    private String getFrom() {
        return " FROM (" + this.sql + ") " + FINALIZE_TABLE_NAME;
    }

    private String getJoin() {
        return Streams.mapWithIndex(this.context.sparqlVarOccurrences().keySet().stream(), (node, index) -> {
                    SPARQLOccurrence maxSPARQLOccurrence = SQLUtils.getMaxSPARQLOccurrence(
                            this.context.sparqlVarOccurrences().get(node)
                    );

                    SQLVariable maxSQLVariable = maxSPARQLOccurrence.getSqlVariable();
                    if (maxSPARQLOccurrence.getType() == SPARQLPositionType.AGGREGATED) {
                        return null;
                    } else {
                        // TODO
                        return " JOIN resource_or_literal rl" + index + " ON " +
                                maxSQLVariable.getSelect(FINALIZE_TABLE_NAME) + " = rl" + index + ".id_resource_or_literal";
                    }
                })
                .filter(Objects::nonNull)
                .collect(Collectors.joining(", "));
    }

    private void flattenAndIdentifyAllVariables() {
        SQLQuery finalQuery = this;

        for (Map.Entry<Node, List<SPARQLOccurrence>> entry : this.context.sparqlVarOccurrences().entrySet()) {
            List<SPARQLOccurrence> sparqlOccurrences = entry.getValue();
            SPARQLOccurrence maxSPARQLOccurrence = SQLUtils.getMaxSPARQLOccurrence(sparqlOccurrences);

            if (maxSPARQLOccurrence.getSqlVariable().getSqlVarType() == SQLVarType.CONDENSED) {
                finalQuery = new FlattenSQLOperator(finalQuery, maxSPARQLOccurrence.getSqlVariable()).buildSQLQuery();
            }

//            if (maxSPARQLOccurrence.getSqlVariable().getSqlVarType() == SQLVarType.ID) {
//                finalQuery = new IdentifySQLOperator(finalQuery, maxSPARQLOccurrence.getSqlVariable()).buildSQLQuery();
//            }
        }

        this.sql = finalQuery.sql;
        this.context = finalQuery.getContext();
        this.opSlice = finalQuery.opSlice;
    }

    private void insertLimit() {
        String select = "SELECT * ";
        String from = " FROM (" + this.sql + ") sl \n";
        String limit;
        if (opSlice.getStart() > 0) {
            limit = "LIMIT " + opSlice.getLength() + " OFFSET " + opSlice.getStart();
        } else {
            limit = "LIMIT " + opSlice.getLength();
        }
        this.sql = select + from + limit;
    }
}
