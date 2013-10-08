package nninf;

import java.util.List;

import checkers.quals.DefaultLocation;
import checkers.types.AnnotatedTypeFactory;
import checkers.types.SubtypingAnnotatedTypeFactory;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.AnnotatedTypeMirror.AnnotatedExecutableType;
import checkers.types.GeneralAnnotatedTypeFactory;
import javacutils.Pair;

import com.sun.source.tree.CompilationUnitTree;
import com.sun.source.tree.MethodInvocationTree;
import com.sun.source.util.TreePath;

public class NninfAnnotatedTypeFactory extends SubtypingAnnotatedTypeFactory<NninfChecker> {
    NninfChecker checker;
    MapGetHeuristics mapGetHeuristics;

    public NninfAnnotatedTypeFactory(NninfChecker checker,
            CompilationUnitTree root) {
        super(checker, root);

        this.checker = checker;

        // TODO: why is this not a KeyForAnnotatedTypeFactory?
        // What qualifiers does it insert? The qualifier hierarchy is null.
        GeneralAnnotatedTypeFactory mapGetFactory = new GeneralAnnotatedTypeFactory(checker, root);
        mapGetHeuristics = new MapGetHeuristics(processingEnv, this, mapGetFactory);

        addAliasedAnnotation(checkers.nullness.quals.NonNull.class,  checker.NONNULL);
        addAliasedAnnotation(checkers.nullness.quals.Nullable.class, checker.NULLABLE);
        addAliasedAnnotation(checkers.nullness.quals.KeyFor.class,   checker.KEYFOR);
        addAliasedAnnotation(checkers.quals.Unqualified.class,       checker.UNKNOWNKEYFOR);

        defaults.addAbsoluteDefault(checker.NONNULL,  DefaultLocation.OTHERWISE);
        defaults.addAbsoluteDefault(checker.NULLABLE, DefaultLocation.LOCAL_VARIABLE);

        postInit();
    }

    /*
     * Handle Map.get heuristics.
     */
    @Override
    public Pair<AnnotatedExecutableType, List<AnnotatedTypeMirror>> methodFromUse(MethodInvocationTree tree) {
        Pair<AnnotatedExecutableType, List<AnnotatedTypeMirror>> mfuPair = super.methodFromUse(tree);
        AnnotatedExecutableType method = mfuPair.first;

        TreePath path = this.getPath(tree);
        if (path!=null) {
            mapGetHeuristics.handle(path, method);
        }
        return mfuPair;
    }
}